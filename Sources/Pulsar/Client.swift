// The Swift Programming Language
// https://docs.swift.org/swift-book

import Bridge
import CxxPulsar
import CxxStdlib
import Foundation
import Logging
import Metrics
import Synchronization

typealias _Pulsar = CxxPulsar.pulsar

/// The Pulsar Client used to connect to a cluster and creating consumers, producers and listeners.
public final class Client: Sendable {

	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: _Pulsar.Client
		init(_ raw: _Pulsar.Client) { self.raw = raw }
		deinit {
			raw.close()
		}
	}

	private let state: Mutex<Box>

	let producersCreated: Counter
	let producersFailed: Counter
	let consumersCreated: Counter
	let consumersFailed: Counter
	let listenersCreated: Counter
	let listenersFailed: Counter

	/// The configuration of the Client.
	public let config: ClientConfiguration
	/// The URL of the Pulsar Cluster.
	///
	/// Per default it should start with `pulsar://` and be available on Port 6650 for non-secure, and start with `pulsar+ssl://` and be on port 6651 for secured clusters.
	public let serviceURL: URL

	/// Initialize a new Pulsar Client.
	/// - Parameters:
	///   - serviceURL: The serviceURL to connect to.
	/// Per default it should start with `pulsar://` and be available on Port 6650 for non-secure, and start with `pulsar+ssl://` and be on port 6651 for secured clusters.
	///   - config: The configuration of the Client.
	public init(serviceURL: URL, authentication: Authentication? = nil, config: ClientConfiguration = ClientConfiguration()) {
		self.serviceURL = serviceURL
		self.config = config
		var rawConfig = config.getConfig()
		if let authentication {
			var authPointer = authentication.authPointer._authPointer
			Bridge_CC_setAuthentication(&rawConfig, &authPointer)
		}
		let raw = _Pulsar.Client(
			std.string(serviceURL.absoluteString),
			rawConfig
		)
		self.state = Mutex(Box(raw))
		self.producersCreated = Counter(label: "pulsar_client_producers_created")
		self.producersFailed = Counter(label: "pulsar_client_producers_failed")
		self.consumersCreated = Counter(label: "pulsar_client_consumers_created")
		self.consumersFailed = Counter(label: "pulsar_client_consumers_failed")
		self.listenersCreated = Counter(label: "pulsar_client_listeners_created")
		self.listenersFailed = Counter(label: "pulsar_client_listeners_failed")
	}

	/// Create a producer.
	/// - Parameters:
	///   - topic: The topic to create the producer on.
	///   - configuration: The producer configuration (optional).
	/// - Returns: The producer.
	public func producer<T: PulsarSchema>(
		for topic: String,
		configuration: ProducerConfiguration = ProducerConfiguration()
	) throws -> Producer<T> {
		// Auto-set schema from the generic type
		try configuration.setCxxSchema(T.self)

		var producer = _Pulsar.Producer()
		var capturedError: Error?

		state.withLock { box in
			let result = box.raw.createProducer(std.string(topic), configuration.getConfig(), &producer)
			if result.rawValue != 0 {
				capturedError = PulsarError(cxx: result)
			}
		}

		if let e = capturedError {
			producersFailed.increment()
			throw e
		}
		producersCreated.increment()
		return Producer(producer: producer, topic: topic)
	}

	/// Subscribe to a topic.
	/// - Parameters:
	///   - topic: The topic to subscribe to.
	///   - subscription: The subscription name.
	///   - configuration: The consumer configuration (optional).
	/// - Returns: The consumer.
	public func consumer<T: PulsarSchema>(
		for topic: String,
		subscription: String,
		configuration: ConsumerConfiguration = ConsumerConfiguration()
	) throws -> Consumer<T> {
		// Auto-set schema from the generic type
		try configuration.setCxxSchema(T.self)

		var consumer = _Pulsar.Consumer()
		var capturedError: Error?
		state.withLock { box in
			let result: pulsar.Result = box.raw.subscribe(
				std.string(topic),
				std.string(subscription),
				configuration.getConfig(),
				&consumer
			)
			if result.rawValue != 0 {
				capturedError = PulsarError(cxx: result)
			}
		}

		if let e = capturedError {
			consumersFailed.increment()
			throw e
		}
		consumersCreated.increment()
		return Consumer(consumer: consumer, subscriptionName: subscription)
	}

	/// Close the client.
	public func close() throws {
		let result = state.withLock { box in
			box.raw.close()
		}
		if result.rawValue != 0 { //ResultOk
			throw PulsarError(cxx: result)
		}
	}

	/// Open a listener on the topic.
	/// - Parameters:
	///   - topic: The topic to listen to.
	///   - subscription: The subscription name.
	/// - Returns: The Listener.
	public func listener<T: PulsarSchema>(on topic: String, subscription: String) throws -> Listener<T> {
		let listener = Listener<T>()
		var configuration = _Pulsar.ConsumerConfiguration()
		let listenerCtx = Unmanaged.passRetained(listener).toOpaque()
		withUnsafeMutablePointer(to: &configuration) { cfgPtr in
			pulsar_consumer_configuration_set_message_listener(
				cfgPtr,
				nil,
				listenerCtx
			)
		}

		var consumer = _Pulsar.Consumer()
		var capturedError: Error?

		state.withLock { box in
			let result: pulsar.Result = box.raw.subscribe(
				std.string(topic),
				std.string(subscription),
				configuration,
				&consumer
			)
			if result.rawValue != 0 {
				capturedError = PulsarError(cxx: result)
			}
		}

		if let e = capturedError {
			Unmanaged<Listener<T>>.fromOpaque(listenerCtx).release()
			listenersFailed.increment()
			throw e
		}

		let consumerWrapper = Consumer<T>(consumer: consumer, listenerContext: listenerCtx, subscriptionName: subscription)
		listener.attach(consumer: consumerWrapper)
		listenersCreated.increment()

		return listener
	}
}

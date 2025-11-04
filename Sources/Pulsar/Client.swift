// The Swift Programming Language
// https://docs.swift.org/swift-book

import Bridge
import CxxPulsar
import CxxStdlib
import Foundation
import Logging
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
	public init(serviceURL: URL, config: ClientConfiguration = ClientConfiguration()) {
		self.serviceURL = serviceURL
		self.config = config
		let raw = _Pulsar.Client(
			std.string(serviceURL.absoluteString),
			config.getConfig()
		)
		self.state = Mutex(Box(raw))
	}

	/// Create a producer.
	/// - Parameter topic: The topic to create the producer on.
	/// - Returns: The producer.
	public func createProducer(topic: String) throws -> Producer {
		var producer = _Pulsar.Producer()
		var capturedError: Error?

		state.withLock { box in
			let result = box.raw.createProducer(std.string(topic), &producer)
			if result.rawValue != 0 {
				capturedError = Result(cxx: result)
			}
		}

		if let e = capturedError { throw e }
		return Producer(producer: producer)
	}

	/// Subscribe to a topic.
	/// - Parameters:
	///   - topic: The topic to subscribe to.
	///   - subscriptionName: The subscription name.
	/// - Returns: The consumer.
	public func subscribe(topic: String, subscriptionName: String) throws -> Consumer {
		var consumer = _Pulsar.Consumer()
		var capturedError: Error?
		state.withLock { box in
			let result: pulsar.Result = box.raw.subscribe(std.string(topic), std.string(subscriptionName), &consumer)
			if result.rawValue != 0 {
				capturedError = Result(cxx: result)
			}
		}

		if let e = capturedError { throw e }
		return Consumer(consumer: consumer)
	}

	/// Cloes the client.
	public func close() throws {
		let result = state.withLock { box in
			box.raw.close()
		}
		if result.rawValue != 0 { //ResultOk
			throw Result(cxx: result)
		}
	}

	/// Open a listener on the topic.
	/// - Parameters:
	///   - topic: The topic to listen to.
	///   - subscriptionName: The subscription name.
	/// - Returns: The Listener.
	public func listen(on topic: String, subscriptionName: String) throws -> Listener {
		let listener = Listener()
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
				std.string(subscriptionName),
				configuration,
				&consumer
			)
			if result.rawValue != 0 {
				capturedError = Result(cxx: result)
			}
		}

		if let e = capturedError {
			Unmanaged<Listener>.fromOpaque(listenerCtx).release()
			throw e
		}

		let consumerWrapper = Consumer(consumer: consumer, listenerContext: listenerCtx)
		listener.attach(consumer: consumerWrapper)

		return listener
	}
}

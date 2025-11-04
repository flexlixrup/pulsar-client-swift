// The Swift Programming Language
// https://docs.swift.org/swift-book

import Bridge
import CxxPulsar
import CxxStdlib
import Foundation
import Logging
import Synchronization

typealias _Pulsar = CxxPulsar.pulsar

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

	public let config: ClientConfiguration
	public let serviceURL: URL

	public init(serviceURL: URL, config: ClientConfiguration = ClientConfiguration()) {
		self.serviceURL = serviceURL
		self.config = config
		let raw = _Pulsar.Client(
			std.string(serviceURL.absoluteString),
			config.getConfig()
		)
		self.state = Mutex(Box(raw))
	}

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

	public func subscribe(topic: String, subscriptionName: String, listen: Bool = false) throws -> Consumer {
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
	public func close() throws {
		let result = state.withLock { box in
			box.raw.close()
		}
		if result.rawValue != 0 { //ResultOk
			throw Result(cxx: result)
		}
	}
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

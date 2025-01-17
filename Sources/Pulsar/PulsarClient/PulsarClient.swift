// Copyright 2025 Felix Ruppert
//
// Licensed under the Apache License, Version 2.0 (the License );
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an AS IS BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Logging
import NIO
import NIOSSL
@_exported import SchemaTypes

/// The core Pulsar Client used to connect to the server.
///
/// This actor manages the connection to a Pulsar server and provides functionality
/// for creating and managing producers and consumers. It also handles configuration
/// of connection parameters and retry mechanisms.
///
/// All interactions with the Pulsar messaging system, such as sending or receiving messages,
/// are controlled through this client.
public final actor PulsarClient {
	let logger = Logger(label: "PulsarClient")
	let group: EventLoopGroup
	var connectionPool: [String: Channel] = [:]
	var initialURL: String
	var port: Int
	let config: PulsarClientConfiguration
	var isReconnecting: Set<String> = []
	var isFirstConnect: Bool = true
	var reconnectLimit: Int?
	var isSecure: Bool
	let tlsConfiguration: TLSConnection?
	/// Callback function called whenever the client gets closed, forcefully or user intended.
	public let onClosed: ((Error) throws -> Void)?

	deinit {
		Task { [weak self] in
			try await self?.close()
		}
	}

	/// Creates a new Pulsar Client and tries to connect it.
	/// - Parameters:
	///   - configuration: The ``PulsarClientConfiguration`` of the client.
	///   - onClosed: The closure that gets executed when the client closes.
	///- throws: Throws an error when the connection fails.
	public init(
		configuration: PulsarClientConfiguration,
		onClosed: (@Sendable (any Error) throws -> Void)?
	) async throws {
		self.config = configuration
		#if DEBUG
			self.group = configuration.group ?? MultiThreadedEventLoopGroup(numberOfThreads: 1)
		#else
			self.group = configuration.group ?? MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
		#endif
		initialURL = configuration.host
		self.port = configuration.port
		self.reconnectLimit = configuration.reconnectionLimit
		isSecure = port == 6651
		self.tlsConfiguration = configuration.tlsConfiguration
		self.onClosed = onClosed
		try await connect(host: initialURL, port: self.port)
	}

	// MARK: - General logic

	func connect(host: String, port: Int) async throws {
		// If already connected to this host, do nothing
		if connectionPool[host] != nil {
			return
		}
		let bootstrap: ClientBootstrap
		// check if the connection is secure
		if isSecure {
			guard let tlsConfiguration else {
				throw PulsarClientError.noTLSProvided
			}
			let sslContext = try NIOSSLContext(configuration: tlsConfiguration.tlsConfiguration)
			bootstrap = ClientBootstrap(group: group)
				.channelInitializer { channel in
					let sslHandler = try! NIOSSLClientHandler(context: sslContext, serverHostname: host)
					return channel.eventLoop.makeCompletedFuture {
						try channel.pipeline.syncOperations.addHandlers([
							sslHandler,
							ByteToMessageHandler(PulsarFrameDecoder()),
							MessageToByteHandler(PulsarFrameEncoder()),
							PulsarClientHandler(eventLoop: self.group.next(), client: self, host: host)
						])
					}
				}
		} else {
			bootstrap = ClientBootstrap(group: group)
				.channelInitializer { channel in
					channel.eventLoop.makeCompletedFuture {
						try channel.pipeline.syncOperations.addHandlers([
							ByteToMessageHandler(PulsarFrameDecoder()),
							MessageToByteHandler(PulsarFrameEncoder()),
							PulsarClientHandler(eventLoop: self.group.next(), client: self, host: host)
						])
					}
				}
		}
		do {
			let channel = try await bootstrap.connect(host: host, port: port).get()
			let handler = try await channel.pipeline.handler(type: PulsarClientHandler.self).get()

			// Store channel if successful
			connectionPool[host] = channel

			// Wait for the handler’s connectionEstablished
			try await handler.connectionEstablished.futureResult.get()
			logger.info("Successfully connected to \(host):\(port)")
		} catch {
			if let error = error as? PulsarClientError {
				if PulsarClientError.isUserHandledError(error) {
					throw error
				}
			}
			connectionPool[host] = nil
			logger.error("Failed to connect to \(host):\(port) - \(error)")
			if isFirstConnect {
				isFirstConnect = false
				await handleChannelInactive(
					ipAddress: initialURL,
					handler: PulsarClientHandler(eventLoop: group.next(), client: self, host: host)
				)
			}
		}
	}

	/// Closes all channels and fails all consumer and producer streams, then throws `clientClosed`.
	public func close() async throws {
		logger.warning("Closing client")

		// Fail all consumer streams (so their AsyncThrowingStream loops exit).
		for channel in connectionPool.values {
			if let handler = try? await channel.pipeline.handler(type: PulsarClientHandler.self).get() {
				for (consumerID, cache) in handler.consumers {
					try await handler.closeConsumer(consumerID: consumerID)
					cache.consumer.fail(error: PulsarClientError.clientClosed)
				}
				for (producerID, _) in handler.producers {
					try await handler.closeProducer(producerID: producerID)
				}
			}
		}

		// Then close the channels
		for (host, channel) in connectionPool {
			do {
				try await channel.close().get()
			} catch {
				logger.error("Failed to close channel for host \(host): \(error)")
			}
		}
		connectionPool.removeAll()
		try onClosed?(PulsarClientError.clientClosed)
		// Finally, inform the caller we are closed
		throw PulsarClientError.clientClosed
	}

	func checkPersistentTopic(topic: String) -> Bool {
		if topic.starts(with: "persistent://") {
			return true
		} else if topic.starts(with: "non-persistent://") {
			return false
		}
		return true
	}

	func getConnection(connectionString: String) -> (String, Int) {
		var str = connectionString
		str = str.replacingOccurrences(of: "pulsar://", with: "")
		let parts = str.split(separator: ":")
		return (String(parts[0]), Int(parts[1]) ?? port)
	}
}

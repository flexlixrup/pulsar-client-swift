// Copyright 2024 Felix Ruppert
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

/// The core Pulsar Client used to connect to the server. All control of the library, like consumers and producers and its settings are controlled via the Client.
public final actor PulsarClient {
	let logger = Logger(label: "PulsarClient")
	let group: EventLoopGroup
	var connectionPool: [String: Channel] = [:]
	var initialURL: String
	var isReconnecting: Set<String> = []
	var isFirstConnect: Bool = true
	var reconnectLimit: Int?
	/// Callback function called whenever the client gets closed, forcefully or user intended.
	public let onClosed: ((Error) throws -> Void)?

	deinit {
		Task { [weak self] in
			try await self?.close()
		}
	}

	/// Creates a new Pulsar Client and tries to connect it.
	/// - Parameters:
	///   - host: The host to connect to. Doesn't need the `pulsar://` prefix.
	///   - port: The port to connect to. Normally `6650`.
	///   - group: If you want to pass your own EventLoopGroup, you can do it here. Otherwise the client will create it's own.
	///   - reconnectLimit: How often the client should try reconnecting, if a connection is lost. The reconnection happens with an exponential backoff. The default limit is 10. Pass `nil` if the client should try reconnecting indefinitely.
	///   - onClosed: If the client gets closed, this function gets called.
	public init(
		host: String,
		port: Int,
		group: EventLoopGroup? = nil,
		reconnectLimit: Int? = 10,
		onClosed: ((Error) throws -> Void)?
	) async {
		#if DEBUG
			self.group = group ?? MultiThreadedEventLoopGroup(numberOfThreads: 1)
		#else
			self.group = group ?? MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
		#endif
		initialURL = host
		self.reconnectLimit = reconnectLimit
		self.onClosed = onClosed
		await connect(host: host, port: port)
	}

	// MARK: - General logic

	func connect(host: String, port: Int) async {
		// If already connected to this host, do nothing
		if connectionPool[host] != nil {
			return
		}
		let bootstrap = ClientBootstrap(group: group)
			.channelInitializer { channel in
				channel.pipeline.addHandlers([
					ByteToMessageHandler(PulsarFrameDecoder()),
					MessageToByteHandler(PulsarFrameEncoder()),
					PulsarClientHandler(eventLoop: self.group.next(), client: self)
				])
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
			connectionPool[host] = nil
			logger.error("Failed to connect to \(host):\(port) - \(error)")
			if isFirstConnect {
				isFirstConnect = false
				await handleChannelInactive(
					ipAddress: initialURL,
					handler: PulsarClientHandler(eventLoop: group.next(), client: self)
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
		return (String(parts[0]), Int(parts[1]) ?? 6650)
	}
}

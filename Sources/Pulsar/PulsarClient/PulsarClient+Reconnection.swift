//
//  PulsarClient+Reconnection.swift
//  pulsar-client-swift
//
//  Created by Felix Ruppert on 26.12.24.
//

extension PulsarClient {
	func handleChannelInactive(ipAddress: String, handler: PulsarClientHandler) async {
		let remoteAddress = ipAddress
		connectionPool.removeValue(forKey: remoteAddress)

		if isReconnecting.contains(ipAddress) {
			logger.info("Already reconnecting to \(ipAddress). Skipping.")
			return
		}

		let oldConsumers = handler.consumers
		logger.warning("Channel inactive for \(ipAddress). Initiating reconnection...")
		isReconnecting.insert(ipAddress)

		let backoff = BackoffStrategy.exponential(
			initialDelay: .seconds(1),
			factor: 2.0,
			maxDelay: .seconds(30)
		)

		var attempt = 0
		let port = 6650
		while true {
			attempt += 1
			do {
				logger.info("Reconnection attempt #\(attempt) to \(remoteAddress):\(port)")

				await connect(host: remoteAddress, port: port)

				// Reattach consumers after reconnecting
				try await reattachConsumers(oldConsumers: oldConsumers, host: remoteAddress)
				isReconnecting.remove(ipAddress)
				logger.info("Reconnected to \(remoteAddress) after \(attempt) attempt(s).")
				break
			} catch {
				logger.error("Reconnection attempt #\(attempt) to \(remoteAddress) failed: \(error)")
				let delay = backoff.delay(forAttempt: attempt)
				logger.warning("Will retry in \(Double(delay.nanoseconds) / 1_000_000_000) second(s).")
				try? await Task.sleep(nanoseconds: UInt64(delay.nanoseconds))
			}
		}
	}

	private func reattachConsumers(
		oldConsumers: [UInt64: ConsumerCache],
		host: String
	) async throws {
		guard let _ = connectionPool[host] else {
			throw PulsarClientError.topicLookupFailed
		}
		logger.debug("Re-attaching \(oldConsumers.count) consumers...")
		for (_, consumerCache) in oldConsumers {
			let oldConsumer = consumerCache.consumer
			let topic = oldConsumer.topic
			let subscription = oldConsumer.subscriptionName
			let consumerID = oldConsumer.consumerID
			let subscriptionType = oldConsumer.subscriptionType
			let subscriptionMode = oldConsumer.subscriptionMode

			logger.info("Re-subscribing consumerID \(consumerCache.consumerID) for topic \(topic)")

			do {
				_ = try await consumer(
					topic: topic,
					subscription: subscription,
					subscriptionType: subscriptionType,
					subscriptionMode: subscriptionMode,
					consumerID: consumerID,
					connectionString: host,
					existingConsumer: oldConsumer
				)
			} catch {
				logger.error("Failed to re-subscribe consumer for topic \(topic): \(error)")
				throw PulsarClientError.consumerClosed
			}
		}
	}
}

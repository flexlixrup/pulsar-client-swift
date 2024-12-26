//
//  PulsarClientHandler+Consumers.swift
//  pulsar-client-swift
//
//  Created by Felix Ruppert on 26.12.24.
//

import NIOCore

extension PulsarClientHandler {
	func closeConsumer(consumerID: UInt64) async throws {
		var baseCommand = Pulsar_Proto_BaseCommand()
		baseCommand.type = .closeConsumer
		var closeCmd = Pulsar_Proto_CommandCloseConsumer()
		let requestID = UInt64.random(in: 0 ..< UInt64.max)
		closeCmd.consumerID = consumerID
		closeCmd.requestID = requestID

		let promise = makePromise(context: correlationMap.context!, type: .id(requestID))
		correlationMap.add(promise: .id(requestID), promiseValue: promise)

		baseCommand.closeConsumer = closeCmd
		let pulsarMessage = PulsarMessage(command: baseCommand)

		try await correlationMap.context!.eventLoop.submit {
			self.correlationMap.context!.writeAndFlush(self.wrapOutboundOut(pulsarMessage), promise: nil)
		}.get()

		try await promise.futureResult.get()
	}

	func acknowledge(context: ChannelHandlerContext, message: PulsarMessage) {
		var baseCommand = Pulsar_Proto_BaseCommand()
		baseCommand.type = .ack
		var ackCmd = Pulsar_Proto_CommandAck()
		ackCmd.messageID = [message.command.message.messageID]
		ackCmd.consumerID = message.command.message.consumerID
		ackCmd.ackType = .individual
		baseCommand.ack = ackCmd
		let pulsarMessage = PulsarMessage(command: baseCommand)
		context.writeAndFlush(wrapOutboundOut(pulsarMessage), promise: nil)
	}

	func subscribe(topic: String,
	               subscription: String,
	               consumerID: UInt64 = UInt64.random(in: 0 ..< UInt64.max),
	               existingConsumer: PulsarConsumer? = nil,
	               subscriptionType: SubscriptionType,
	               subscriptionMode: SubscriptionMode) async throws -> PulsarConsumer {
		var baseCommand = Pulsar_Proto_BaseCommand()
		baseCommand.type = .subscribe
		var subscribeCmd = Pulsar_Proto_CommandSubscribe()
		subscribeCmd.topic = topic
		subscribeCmd.subscription = subscription
		let requestID = UInt64.random(in: 0 ..< UInt64.max)
		subscribeCmd.requestID = requestID
		subscribeCmd.subType = switch subscriptionType {
			case .exclusive:
				.exclusive
			case .failover:
				.failover
			case .keyShared:
				.keyShared
			case .shared:
				.shared
		}
		subscribeCmd.consumerID = consumerID

		let promise = makePromise(context: correlationMap.context!, type: .id(requestID))
		correlationMap.add(promise: .id(requestID), promiseValue: promise)

		baseCommand.subscribe = subscribeCmd
		let pulsarMessage = PulsarMessage(command: baseCommand)

		// We add the consumer to the pool before connection, so in case the subscription attempt fails and we
		// need to reconnect, we already know the consumers we wanted.
		let consumer = existingConsumer ?? PulsarConsumer(
			handler: self,
			consumerID: consumerID,
			topic: topic,
			subscriptionName: subscription,
			subscriptionType: subscriptionType,
			subscriptionMode: subscriptionMode
		)
		consumers[consumerID] = ConsumerCache(consumerID: consumerID, consumer: consumer)

		// Write/flush on the event loop, can be called externally, so we must put it on the eventLoop explicitly.
		try await correlationMap.context!.eventLoop.submit {
			self.correlationMap.context!.writeAndFlush(self.wrapOutboundOut(pulsarMessage), promise: nil)
		}.get()

		// Wait for the broker to respond with success (or error)
		try await promise.futureResult.get()

		// Create the consumer object and track it
		logger.info("Successfully subscribed to \(topic) with subscription: \(subscription)")

		// Issue initial flow permit
		try await correlationMap.context!.eventLoop.submit {
			self.flow(consumerID: consumerID, isInitial: true)
		}.get()

		return consumer
	}

	/// Permit new flow from broker to consumer.
	/// - Parameters:
	///   - consumerID: The id of the consumer to permit the message flow to.
	///   - isInitial: If it's initial request we request 1000, otherwise 500 more as per Pulsar protocol.
	func flow(consumerID: UInt64, isInitial: Bool = false) {
		var baseCommand = Pulsar_Proto_BaseCommand()
		baseCommand.type = .flow
		var flowCmd = Pulsar_Proto_CommandFlow()
		flowCmd.messagePermits = isInitial ? 1000 : 500
		flowCmd.consumerID = consumerID
		baseCommand.flow = flowCmd
		let pulsarMessage = PulsarMessage(command: baseCommand)
		correlationMap.context?.writeAndFlush(wrapOutboundOut(pulsarMessage), promise: nil)
	}

	/// The broker told us the consumer is being closed. We can fail the stream and (optionally) try re-subscribing.
	func handleClosedConsumer(consumerID: UInt64) {
		guard let consumerCache = consumers[consumerID] else {
			logger.warning("Received closeConsumer for unknown consumerID \(consumerID)")
			return
		}
		let consumer = consumerCache.consumer
		logger.warning("Server closed consumerID \(consumerID) for topic \(consumer.topic)")

		// Optional: attempt a re-subscribe
		Task {
			do {
				logger.info("Attempting to re-subscribe consumer for \(consumer.topic)...")
				_ = try await client.consumer(topic: consumer.topic, subscription: consumer.subscriptionName, subscriptionType: .shared)
				logger.info("Successfully re-subscribed \(consumer.topic)")
			} catch {
				logger.error("Re-subscribe failed for \(consumer.topic): \(error)")
			}
		}
	}
}

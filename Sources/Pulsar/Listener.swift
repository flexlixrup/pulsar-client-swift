@preconcurrency import CxxPulsar
import CxxStdlib
import Logging
import Metrics
import Synchronization

/// A Pulsar Message Listener.
///
/// The listener is modeled as an async sequence, to consume messages as a stream, use the following code:
///
/// ```swift
///	for try await message in listener {
///		print("Received message: \(message.content)")
///		try listener.acknowledge(message)
/// }
/// ```
///
/// The listener will contiously consume messages until ``close()`` is called.
public final class Listener<T: PulsarSchema>: Sendable, AsyncSequence {
	let logger = Logger(label: "Listener")
	private let stream: AsyncThrowingStream<Message<T>, Error>
	let continuation: AsyncThrowingStream<Message<T>, Error>.Continuation
	let messagesReceived: Counter
	let acknowledgementsAll: Counter
	let acknowledgementsFailed: Counter
	let acknowledgementsSuccess: Counter

	final class ConsumerBox: @unchecked Sendable {
		var consumer: Consumer<T>?
		init(_ c: Consumer<T>?) { self.consumer = c }
	}

	private let consumerState: Mutex<ConsumerBox>

	public func makeAsyncIterator() -> AsyncThrowingStream<Message<T>, Error>.AsyncIterator {
		stream.makeAsyncIterator()
	}

	init() {
		var cont: AsyncThrowingStream<Message<T>, Error>.Continuation!
		stream = AsyncThrowingStream { c in
			cont = c
		}
		continuation = cont
		self.consumerState = Mutex(ConsumerBox(nil))
		self.messagesReceived = Counter(label: "pulsar_listener_messages_received")
		self.acknowledgementsAll = Counter(label: "pulsar_listener_acknowledgements_all")
		self.acknowledgementsFailed = Counter(label: "pulsar_listener_acknowledgements_failed")
		self.acknowledgementsSuccess = Counter(label: "pulsar_listener_acknowledgements_success")
	}

	func attach(consumer: Consumer<T>) {
		consumerState.withLock { box in
			box.consumer = consumer
		}
	}

	/// Acknowledge a message the listener received.
	/// - Parameter message: The message to acknowledge.
	public func acknowledge(_ message: Message<T>) throws {
		acknowledgementsAll.increment()
		do {
			try consumerState.withLock { box in
				guard let consumer = box.consumer else {
					throw PulsarError.consumerNotFound
				}
				try consumer.acknowledge(message)
			}
			acknowledgementsSuccess.increment()
		} catch {
			acknowledgementsFailed.increment()
			throw error
		}
	}

	public func acknowledge(_ message: Message<T>) async throws {
		acknowledgementsAll.increment()
		do {
			let consumer = try consumerState.withLock { box -> Consumer in
				guard let consumer = box.consumer else {
					throw PulsarError.consumerNotFound
				}
				return consumer
			}

			try await consumer.acknowledge(message)
			acknowledgementsSuccess.increment()
		} catch {
			acknowledgementsFailed.increment()
			throw error
		}
	}

	/// Close the listener.
	public func close() throws {
		logger.info("Listener closed")
		try consumerState.withLock { box in
			if let consumer = box.consumer {
				try consumer.close()
			}
			box.consumer = nil
		}
	}

	func receive(message: Message<T>, consumerPtr: UnsafeMutableRawPointer?) {
		logger.debug("Message received, yielding to stream")
		messagesReceived.increment()
		consumerState.withLock { box in
			box.consumer?.counterAll.increment()
		}
		continuation.yield(message)
	}
}

// Protocol to handle messages in a type-erased way
protocol MessageReceiver: AnyObject {
	func receiveRawMessage(_ rawMsg: _Pulsar.Message, consumerPtr: UnsafeMutableRawPointer?)
}

extension Listener: MessageReceiver {
	func receiveRawMessage(_ rawMsg: _Pulsar.Message, consumerPtr: UnsafeMutableRawPointer?) {
		let message = Message<T>(rawMsg)
		receive(message: message, consumerPtr: consumerPtr)
	}
}

@_cdecl("pulsar_swift_message_listener")
func messageListenerCallback(
	_ ctx: UnsafeMutableRawPointer?,
	_ consumerPtr: UnsafeMutableRawPointer?,
	_ messagePtr: UnsafeRawPointer?
) {
	guard let msgPtr = messagePtr, let ctx = ctx else { return }

	// Copy the message to avoid capture issues
	let rawMsg = msgPtr.assumingMemoryBound(to: _Pulsar.Message.self).pointee
	let consumerAddress: UInt? = consumerPtr.map { UInt(bitPattern: $0) }
	let ctxAddress = UInt(bitPattern: ctx)

	// We use an explicit @Sendable closure and trust that the C++ message copy is safe
	Task.detached { @Sendable in
		let logger: Logger = Logger(label: "ListenerCallback")
		let restoredCtx = UnsafeMutableRawPointer(bitPattern: ctxAddress)!
		let restoredConsumerPtr = consumerAddress.flatMap { UnsafeMutableRawPointer(bitPattern: $0) }

		// Get the listener as MessageReceiver (type-erased)
		let listenerObj = Unmanaged<AnyObject>.fromOpaque(restoredCtx).takeUnretainedValue()
		guard let receiver = listenerObj as? MessageReceiver else {
			logger.error("Context does not contain a valid MessageReceiver")
			return
		}

		logger.debug("Listener received message via C++ callback")
		receiver.receiveRawMessage(rawMsg, consumerPtr: restoredConsumerPtr)
	}
}

import CxxPulsar
import CxxStdlib
import Logging
import Synchronization

public final class Listener: Sendable, AsyncSequence {
	let logger = Logger(label: "Listener")
	private let stream: AsyncThrowingStream<Message, Error>
	let continuation: AsyncThrowingStream<Message, Error>.Continuation

	final class ConsumerBox: @unchecked Sendable {
		var consumer: Consumer?
		init(_ c: Consumer?) { self.consumer = c }
	}

	private let consumerState: Mutex<ConsumerBox>

	public func makeAsyncIterator() -> AsyncThrowingStream<Message, Error>.AsyncIterator {
		stream.makeAsyncIterator()
	}

	public init() {
		var cont: AsyncThrowingStream<Message, Error>.Continuation!
		stream = AsyncThrowingStream { c in
			cont = c
		}
		continuation = cont
		self.consumerState = Mutex(ConsumerBox(nil))
	}

	func attach(consumer: Consumer) {
		consumerState.withLock { box in
			box.consumer = consumer
		}
	}

	public func acknowledge(_ message: Message) throws {
		try consumerState.withLock { box in
			guard let consumer = box.consumer else {
				throw Result.consumerNotFound
			}
			try consumer.acknowledge(message)
		}
	}

	public func close() throws {
		try consumerState.withLock { box in
			if let consumer = box.consumer {
				try consumer.close()
			}
			box.consumer = nil
		}
	}
}

extension Listener {
	static let shared = Listener()

	func receive(message: Message, consumerPtr: UnsafeMutableRawPointer?) {
		logger.debug("Message received, yielding to stream")
		continuation.yield(message)
	}
}
@_cdecl("pulsar_swift_message_listener")
func messageListenerCallback(
	_ ctx: UnsafeMutableRawPointer?,
	_ consumerPtr: UnsafeMutableRawPointer?,
	_ messagePtr: UnsafeRawPointer?
) {
	let logger: Logger = Logger(label: "ListenerCallback")
	guard let msgPtr = messagePtr else { return }

	let rawMsg = msgPtr.assumingMemoryBound(to: _Pulsar.Message.self).pointee
	let message = Message(rawMsg)

	let listener: Listener = {
		guard let ctx = ctx else {
			return Listener.shared
		}
		return Unmanaged<Listener>.fromOpaque(ctx).takeUnretainedValue()
	}()

	let consumerAddress: UInt? = consumerPtr.map { UInt(bitPattern: $0) }

	Task.detached { [listener, message, consumerAddress] in
		let restoredConsumerPtr = consumerAddress.flatMap { UnsafeMutableRawPointer(bitPattern: $0) }
		logger.debug("Listener received message via C++ callback")
		listener.receive(message: message, consumerPtr: restoredConsumerPtr)
	}
}

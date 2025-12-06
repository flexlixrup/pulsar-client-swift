import Bridge
import CxxPulsar
import Logging
import Metrics
import Synchronization

final class ResultContinuationBox: Sendable {
	let cont: CheckedContinuation<Void, Error>
	init(_ cont: CheckedContinuation<Void, Error>) { self.cont = cont }
}
/// A Consumer to consume messages.
///
/// This consumer can receive single messages and batch messages in a user-controlled pull-fashion. To continously receive messages in a stream, use the ``Listener``.
public final class Consumer<T: PulsarSchema>: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: _Pulsar.Consumer
		var listenerContext: UnsafeMutableRawPointer?
		init(_ raw: _Pulsar.Consumer) { self.raw = raw }
		deinit {
			if let ctx = listenerContext {
				Unmanaged<Listener<T>>.fromOpaque(ctx).release()
			}
		}
	}

	let counterAll: Counter
	let subscriptionName: String
	let counterFailed: Counter
	let counterSuccess: Counter
	private let state: Mutex<Box>

	init(consumer: _Pulsar.Consumer, listenerContext: UnsafeMutableRawPointer? = nil, subscriptionName: String) {
		let box = Box(consumer)
		box.listenerContext = listenerContext
		self.state = Mutex(box)
		self.subscriptionName = subscriptionName
		self.counterAll = Counter(label: "pulsar_consumer_messages_sent_\(subscriptionName)")
		self.counterFailed = Counter(label: "pulsar_consumer_messages_failed_\(subscriptionName)")
		self.counterSuccess = Counter(label: "pulsar_consumer_messages_successful_\(subscriptionName)")
	}

	/// Receive a single message and block until the message has been received.
	/// - Parameter timeout: The timeout, if no message is received in time, the method will throw.
	/// - Returns: The received message
	public func receive(timeout: Duration = .zero) throws -> Message<T> {
		var cppMessage = _Pulsar.Message()
		var result: pulsar.Result
		if timeout != .zero {
			let timeoutMs = toMilliseconds(timeout)
			result = state.withLock { box in
				box.raw.receive(&cppMessage, Int32(timeoutMs))
			}
		} else {
			result = state.withLock { box in
				box.raw.receive(&cppMessage)
			}
		}
		self.counterAll.increment()
		if result.rawValue != 0 { //ResultOk
			self.counterFailed.increment()
			throw Result(cxx: result)
		}
		self.counterSuccess.increment()
		return Message<T>(cppMessage)
	}

	/// Close the consumer synchronously.
	public func close() throws {
		let result = state.withLock { box in
			box.raw.close()
		}
		if result.rawValue != 0 { //ResultOk
			throw Result(cxx: result)
		}
	}

	/// Acknowledge a message.
	/// - Parameter message: The message to acknowledge.
	public func acknowledge(_ message: Message<T>) throws {
		let result = state.withLock { box in
			box.raw.acknowledge(message.rawMessage)
		}
		if result.rawValue != 0 { //ResultOk
			throw Result(cxx: result)
		}
	}

	public func acknowledgeAsync(_ message: Message<T>) async throws {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			let boxObj = ContinuationBox(continuation)
			let ctx = Unmanaged.passRetained(boxObj).toOpaque()

			state.withLock { box in
				withUnsafeMutablePointer(to: &box.raw) { consPtr in
					withUnsafePointer(to: message.rawMessage) { msgPtr in
						pulsar_consumer_acknowledge_async(
							UnsafeMutableRawPointer(mutating: consPtr),
							UnsafeRawPointer(msgPtr),
							ctx
						)
					}
				}
			}
		}
	}
}

@_cdecl("pulsar_swift_result_callback")
func resultCallback(_ ctx: UnsafeMutableRawPointer?, _ result: Int32) {
	let logger: Logger = Logger(label: "ResultCallback")
	guard let ctx = ctx else {
		logger.error("resultCallback called with null context")
		return
	}

	let any = Unmanaged<AnyObject>.fromOpaque(ctx).takeRetainedValue()

	if let contBox = any as? ContinuationBox {
		contBox.checkContinuation(result: result, context: "resultCallback")
	}

}

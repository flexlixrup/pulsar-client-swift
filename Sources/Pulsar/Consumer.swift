import Bridge
import CxxPulsar
import Logging
import Synchronization

final class ResultContinuationBox: Sendable {
	let cont: CheckedContinuation<Void, Error>
	init(_ cont: CheckedContinuation<Void, Error>) { self.cont = cont }
}
/// A Consumer to consume messages.
///
/// This consumer can receive single messages and batch messages in a user-controlled pull-fashion. To continously receive messages in a stream, use the ``Listener``.
public final class Consumer: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: _Pulsar.Consumer
		var listenerContext: UnsafeMutableRawPointer?
		init(_ raw: _Pulsar.Consumer) { self.raw = raw }
		deinit {
			if let ctx = listenerContext {
				Unmanaged<Listener>.fromOpaque(ctx).release()
			}
		}
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
	private let state: Mutex<Box>

	init(consumer: _Pulsar.Consumer, listenerContext: UnsafeMutableRawPointer? = nil) {
		let box = Box(consumer)
		box.listenerContext = listenerContext
		self.state = Mutex(box)
	}

	/// Acknowledge a message.
	/// - Parameter message: The message to acknowledge.
	public func acknowledge(_ message: Message) throws {
		let result = state.withLock { box in
			box.raw.acknowledge(message.rawMessage)
		}
		if result.rawValue != 0 { //ResultOk
			throw Result(cxx: result)
		}
	}

	public func acknowledgeAsync(_ message: Message) async throws {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			let boxObj = ContinuationBox(continuation)
			let ctx = Unmanaged.passRetained(boxObj).toOpaque()

			state.withLock { box in
				withUnsafeMutablePointer(to: &box.raw) { consPtr in
					withUnsafePointer(to: message.rawMessage) { msgPtr in
						pulsar_consumer_acknowledge_async(
							UnsafeMutableRawPointer(mutating: consPtr),
							UnsafeRawPointer(msgPtr),
							nil,
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

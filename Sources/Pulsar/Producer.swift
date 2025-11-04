import Bridge
import CxxPulsar
import Foundation
import Logging
import Synchronization

/// A Producer to produce Pulsar messages-
public final class Producer: Sendable {

	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: _Pulsar.Producer
		init(_ raw: _Pulsar.Producer) { self.raw = raw }
		deinit {
			raw.close()
		}
	}

	private let state: Mutex<Box>

	init(producer: _Pulsar.Producer) {
		self.state = Mutex(Box(producer))
	}

	/// Send a message synchronously.
	/// - Parameter message: The message to send.
	///
	/// This method will block until the server acknowledged the message. Use ``sendAsync(_:)`` for the non-blocking version.
	public func send(_ message: Message) throws {
		var capturedError: Error?

		state.withLock { box in
			var messageId = _Pulsar.MessageId()
			let result = box.raw.send(message.rawMessage, &messageId)
			if result.rawValue != 0 {
				capturedError = Result(cxx: result)
			}
		}

		if let e = capturedError { throw e }
	}

	/// Send a message asynchronously.
	/// - Parameter message: The message to send.
	///
	/// This method waits for the acknowledgement in a non-blocking fashion. To block the thread until the acknowledgement has been received, use ``send(_:)`` instead.
	public func sendAsync(_ message: Message) async throws {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			let boxObj = ContinuationBox(continuation)
			let ctx = Unmanaged.passRetained(boxObj).toOpaque()

			state.withLock { box in
				withUnsafeMutablePointer(to: &box.raw) { prodPtr in
					withUnsafePointer(to: message.rawMessage) { msgPtr in
						pulsar_producer_send_async(UnsafeMutableRawPointer(mutating: prodPtr), UnsafeRawPointer(msgPtr), nil, ctx)
					}
				}
			}
		}
	}
}

@_cdecl("pulsar_swift_send_callback")
func sendCallback(_ ctx: UnsafeMutableRawPointer?, _ result: Int32, _ messageIdPtr: UnsafeRawPointer?) {
	let logger: Logger = Logger(label: "ProducerCallback")
	guard let ctx = ctx else {
		logger.error("sendCallback called with null context")
		return
	}
	let any = Unmanaged<AnyObject>.fromOpaque(ctx).takeRetainedValue()

	if let contBox: ContinuationBox = any as? ContinuationBox {
		contBox.checkContinuation(result: result, context: "sendCallback")
	}
}

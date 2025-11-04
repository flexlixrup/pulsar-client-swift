import Bridge
import CxxPulsar
import Foundation
import Logging
import Synchronization

final class ProducerSendContinuationBox: @unchecked Sendable {
	let cont: CheckedContinuation<Void, Error>
	init(_ cont: CheckedContinuation<Void, Error>) { self.cont = cont }
}

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

	public func sendAsync(_ message: Message) async throws {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			let boxObj = ProducerSendContinuationBox(continuation)
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
	guard let ctx = ctx else { return }
	let any = Unmanaged<AnyObject>.fromOpaque(ctx).takeRetainedValue()

	if let contBox = any as? ProducerSendContinuationBox {
		if result == 0 {
			logger.debug("Received ResultOk from send callback")
			contBox.cont.resume()
		} else {
			let converted = Result(cxx: _Pulsar.Result(rawValue: result))
			logger.debug("Received error from send callback: \(converted)")
			contBox.cont.resume(throwing: converted)
		}
	}
}

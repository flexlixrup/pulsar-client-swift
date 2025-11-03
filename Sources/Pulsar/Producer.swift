import CxxPulsar
import Synchronization

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
			let result = box.raw.send(message.getRawMessage(), &messageId)
			if result.rawValue != 0 {
				capturedError = Result(cxx: result)
			}
		}

		if let e = capturedError { throw e }
	}
}

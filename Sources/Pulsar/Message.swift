import CxxPulsar
import CxxStdlib
import Synchronization

public final class Message: Sendable {

	final class Box: @unchecked Sendable {
		var raw: _Pulsar.Message
		init(_ raw: _Pulsar.Message) { self.raw = raw }
	}

	private let state: Mutex<Box>

	public init(content: String) {
		var messageBuilder: _Pulsar.MessageBuilder = _Pulsar.MessageBuilder()
		let utf8Content = Array(content.utf8)
		utf8Content.withUnsafeBytes { buffer in
			messageBuilder.setContent(buffer.baseAddress!, size: buffer.count)
		}
		self.state = Mutex(Box(messageBuilder.build()))
	}

	init(_ raw: _Pulsar.Message) {
		self.state = Mutex(Box(raw))
	}

	var rawMessage: _Pulsar.Message {
		state.withLock { box in box.raw }
	}

	public var content: String {
		state.withLock { box in
			let rawContent = box.raw.getDataAsString()
			return String(rawContent)
		}
	}
}

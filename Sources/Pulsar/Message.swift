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
		messageBuilder.setContent(std.string(content))
		self.state = Mutex(Box(messageBuilder.build()))
	}

	/// Create a Swift `Message` wrapper around an existing C++ `_Pulsar.Message`.
	/// This is used by the listener callback to forward incoming messages into Swift.
	init(_ raw: _Pulsar.Message) {
		self.state = Mutex(Box(raw))
	}

	func getRawMessage() -> _Pulsar.Message {
		state.withLock { box in box.raw }
	}

	public var content: String {
		state.withLock { box in
			let rawContent = box.raw.getDataAsString()
			return String(rawContent)
		}
	}
}

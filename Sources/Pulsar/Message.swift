import Bridge
import CxxPulsar
import CxxStdlib
import Foundation
import Synchronization

public final class Message<T: PulsarSchema>: Sendable {

	final class Box: @unchecked Sendable {
		var raw: _Pulsar.Message
		init(_ raw: _Pulsar.Message) { self.raw = raw }
	}

	private let state: Mutex<Box>

	public init(content: T) throws {
		var messageBuilder: _Pulsar.MessageBuilder = _Pulsar.MessageBuilder()
		let contentData = try content.encode()
		contentData.withUnsafeBytes { buffer in
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

	public var content: T {
		get throws {
			let data = try state.withLock { box in
				var dataPtr: UnsafeMutableRawPointer?
				let size = withUnsafePointer(to: box.raw) { msgPtr in
					getDataFromMessage(UnsafeRawPointer(msgPtr), &dataPtr)
				}

				guard let dataPtr = dataPtr, size > 0 else {
					throw PulsarError.invalidMessage
				}

				defer {
					free(dataPtr)
				}

				return Data(bytes: dataPtr, count: size)
			}
			return try T.decode(data)
		}
	}
}

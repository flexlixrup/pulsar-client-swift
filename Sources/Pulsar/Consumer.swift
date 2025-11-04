import CxxPulsar
import Logging
import Synchronization

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

	public func acknowledge(_ message: Message) throws {
		let result = state.withLock { box in
			box.raw.acknowledge(message.rawMessage)
		}
		if result.rawValue != 0 { //ResultOk
			throw Result(cxx: result)
		}
	}

}

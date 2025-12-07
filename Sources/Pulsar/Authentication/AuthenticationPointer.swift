import CxxPulsar
import Synchronization

/// A thread-safe wrapper for the C++ authentication pointer.
public final class AuthPointer: @unchecked Sendable {

	final class Box: @unchecked Sendable {
		var raw: _Pulsar.AuthenticationPtr
		init(_ raw: _Pulsar.AuthenticationPtr) { self.raw = raw }
	}
	private let state: Mutex<Box>

	init(_ raw: _Pulsar.AuthenticationPtr) {
		self.state = Mutex(Box(raw))
	}

	var _authPointer: _Pulsar.AuthenticationPtr {
		state.withLock { box in box.raw }
	}
}

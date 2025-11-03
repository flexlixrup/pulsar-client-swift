import CxxPulsar
import Synchronization

public final class Consumer: Sendable {

	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: _Pulsar.Consumer
		init(_ raw: _Pulsar.Consumer) { self.raw = raw }
		deinit {
			raw.close()
		}
	}

	private let state: Mutex<Box>

	init(consumer: _Pulsar.Consumer) {
		self.state = Mutex(Box(consumer))
	}

}

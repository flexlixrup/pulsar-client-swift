import Bridge
import CxxPulsar

extension CxxPulsar.pulsar.MessageBuilder {

	@inline(__always)
	private mutating func _withMutPtr<Result>(
		_ body: (UnsafeMutablePointer<Self>) throws -> Result
	) rethrows -> Result {
		try withUnsafeMutablePointer(to: &self, body)
	}

	mutating func setContent(_ bytes: UnsafeRawPointer, size: Int) {
		_withMutPtr { Bridge_MB_setContent($0, bytes, numericCast(size)) }
	}

	mutating func setProperty(_ name: String, value: String) {
		_withMutPtr { ptr in
			name.withCString { n in
				value.withCString { v in
					Bridge_MB_setProperty(ptr, n, v)
				}
			}
		}
	}

	mutating func setAllocatedContent(_ p: UnsafeMutableRawPointer, size: Int) {
		_withMutPtr { Bridge_MB_setAllocatedContent($0, p, numericCast(size)) }
	}

	mutating func setDeliver(at millis: UInt64) {
		_withMutPtr { Bridge_MB_setDeliverAt($0, millis) }
	}

	mutating func disableReplication(_ flag: Bool) {
		_withMutPtr { Bridge_MB_disableReplication($0, flag) }
	}
}

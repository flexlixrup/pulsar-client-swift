// Helpers to convert Swift Duration -> seconds / milliseconds
@inline(__always)
@inlinable
func toSeconds(_ d: Duration) -> Int {
	let comps = d.components
	// Round toward zero; Pulsar takes integer seconds
	return Int(comps.seconds)
}

@inline(__always)
@inlinable
func toMilliseconds(_ d: Duration) -> Int {
	let comps = d.components
	// 1 second = 1_000 ms; 1 ms = 1_000_000_000_000_000 attoseconds
	let wholeSecMs = Int(comps.seconds) * 1_000
	let fracMs = Int(comps.attoseconds / 1_000_000_000_000_000)
	return wholeSecMs &+ fracMs
}

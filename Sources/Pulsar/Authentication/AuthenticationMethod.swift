import CxxPulsar

public protocol AuthenticationMethod: Sendable {
	var authPointer: AuthPointer { get }
}

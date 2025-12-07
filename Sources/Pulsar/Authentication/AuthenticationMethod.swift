import CxxPulsar

/// Protocol for authentication methods.
public protocol AuthenticationMethod: Sendable {
	var authPointer: AuthPointer { get }
}

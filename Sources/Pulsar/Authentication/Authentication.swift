import Foundation

/// Authentication method for Pulsar client connections.
public enum Authentication {
	case token(TokenAuthentication)

	var method: any AuthenticationMethod {
		switch self {
			case .token(let m): m
		}
	}
	var authPointer: AuthPointer { method.authPointer }
}

import CxxStdlib
import Foundation

public struct TokenAuthentication: AuthenticationMethod, Sendable {

	public let token: String

	public init(fromString token: String) {
		self.token = token
	}

	public init(fromFile tokenFilePath: URL) throws {
		self.token = try String(contentsOf: tokenFilePath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
	}

	public init(fromEnv variable: String) throws {
		guard let token = ProcessInfo.processInfo.environment[variable] else {
			throw PulsarError.authenticationError("Token not found in environment under variable \(variable)")
		}
		self.token = token
	}

	public init(fromClosure tokenProvider: () throws -> String) rethrows {
		self.token = try tokenProvider()
	}

	public var authPointer: AuthPointer {
		var params = _Pulsar.ParamMap(["token": std.string(token)])
		return AuthPointer(_Pulsar.AuthToken.create(&params))
	}
}

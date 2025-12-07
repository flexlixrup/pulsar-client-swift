import CxxStdlib
import Foundation

/// Token-based authentication for Pulsar.
public struct TokenAuthentication: AuthenticationMethod, Sendable {

	/// The JWT token string.
	public let token: String

	init(fromString token: String) {
		self.token = token
	}

	init(fromFile tokenFilePath: URL) throws {
		self.token = try String(contentsOf: tokenFilePath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
	}

	init(fromEnv variable: String) throws {
		guard let token = ProcessInfo.processInfo.environment[variable] else {
			throw PulsarError.authenticationError
		}
		self.token = token
	}

	init(fromClosure tokenProvider: () throws -> String) rethrows {
		self.token = try tokenProvider()
	}

	/// Gets the authentication pointer for use with the C++ client.
	public var authPointer: AuthPointer {
		var params = _Pulsar.ParamMap(["token": std.string(token)])
		return AuthPointer(_Pulsar.AuthToken.create(&params))
	}
}

extension Authentication {
	/// Create token authentication from a string token.
	/// - Parameter token: The JWT token string.
	/// - Returns: An Authentication instance configured with the token.
	public static func token(fromString token: String) -> Authentication {
		.token(TokenAuthentication(fromString: token))
	}

	/// Create token authentication from a file.
	/// - Parameter tokenFilePath: The URL to the file containing the token.
	/// - Returns: An Authentication instance configured with the token.
	/// - Throws: If the file cannot be read.
	public static func token(fromFile tokenFilePath: URL) throws -> Authentication {
		try .token(TokenAuthentication(fromFile: tokenFilePath))
	}

	/// Create token authentication from an environment variable.
	/// - Parameter variable: The name of the environment variable containing the token.
	/// - Returns: An Authentication instance configured with the token.
	/// - Throws: If the environment variable is not found.
	public static func token(fromEnv variable: String) throws -> Authentication {
		try .token(TokenAuthentication(fromEnv: variable))
	}

	/// Create token authentication from a closure.
	/// - Parameter tokenProvider: A closure that returns the token string.
	/// - Returns: An Authentication instance configured with the token.
	/// - Throws: If the closure throws an error.
	public static func token(fromClosure tokenProvider: () throws -> String) rethrows -> Authentication {
		try .token(TokenAuthentication(fromClosure: tokenProvider))
	}
}

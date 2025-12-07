import Foundation
import Pulsar
import Testing

@Suite("AuthenticationIntegrationTests", .serialized, .disabled(if: ProcessInfo.processInfo.environment["CI"] == "true"))
struct AuthenticationIntegrationTests {
	@Test("Token Authentication positive test")
	func tokenAuthenticationTest() throws {
		let client: Client = Client(
			serviceURL: URL(string: "pulsar://localhost:6650")!,
			authentication: .token(
				fromString: "token"
			)
		)
		let producer: Producer<String> = try client.producer(for: "persistent://public/secure/authentication-token-test")
		let message = try Message<String>(content: "Hello, Pulsar with Token Auth!")
		try producer.send(message)
		let consumer: Consumer<String> = try client.consumer(
			for: "persistent://public/secure/authentication-token-test",
			subscription: "authentication-token-subscription"
		)
		let receivedMessage = try consumer.receive(within: .seconds(10))
		try consumer.close()
		try client.close()
		let content = try receivedMessage.content
		#expect(content == "Hello, Pulsar with Token Auth!")
	}

	@Test("Token Authentication negative test")
	func tokenAuthenticationNegativeTest() throws {
		do {
			let client: Client = Client(
				serviceURL: URL(string: "pulsar://localhost:6650")!,
				authentication: .token(
					fromString: "invalid-token"
				)
			)
			let producer: Producer<String> = try client.producer(for: "persistent://public/secure/authentication-token-test")
			let message = try Message<String>(content: "This should not be sent!")
			try producer.send(message)
			#expect(false, "Expected authentication to fail, but it succeeded.")
		} catch {
			#expect(true, "Authentication failed as expected with error: \(error)")
		}
	}
}

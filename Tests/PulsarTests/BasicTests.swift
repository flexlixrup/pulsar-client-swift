import CxxPulsar
import Foundation
import Testing

@testable import Pulsar

@Suite("Basic Tests")
struct BasicTests {
	@Test("Main Queue Producer")
	func mainQueueProducer() async throws {
		let client = Client(serviceURL: URL(string: "pulsar://localhost:6650")!)
		let producer = try client.createProducer(topic: "persistent://public/default/my-topic")
		let message = Message(content: "Hello from Swift!")
		#expect(throws: Never.self) {
			try producer.send(message)
		}
	}
	@Test("Main Queue Listener")
	func mainQueueConsumer() async throws {
		let client = Client(serviceURL: URL(string: "pulsar://localhost:6650")!)
		let listener = try client.listen(on: "persistent://public/default/my-topic", subscriptionName: "my-subscription")
		var counter = 0
		await #expect(throws: Never.self) {
			for try await msg in listener {
				print("Received message with content: \(msg.content)")
				counter += 1
				if counter >= 1 {
					break
				}
			}
		}
	}
}

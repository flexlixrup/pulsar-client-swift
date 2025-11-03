import Foundation
import Pulsar

@main
struct Example {
	static func main() async throws {
		let client = try Client(serviceURL: URL(string: "pulsar://localhost:6650")!)
		Task {
			let producer = try client.createProducer(topic: "persistent://public/default/my-topic")
			for i in 1 ... 10 {
				let content = "Hello Pulsar \(i)"
				let message = Message(content: "Hello Pulsar \(i)")
				try producer.send(message)
				print("Sent message: \(content)")
				try await Task.sleep(nanoseconds: 500_000_000)
			}
		}
		let listener = try client.listen(on: "persistent://public/default/my-topic", subscriptionName: "my-subscription")

		for try await message in listener {
			print("Received message: \(message.content)")
		}
	}
}

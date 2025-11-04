import Foundation
import Logging
import Pulsar

@main
struct Example {
	static func main() async throws {
		LoggingSystem.bootstrap { label in
			var handler = StreamLogHandler.standardOutput(label: label)
			handler.logLevel = .trace
			return handler
		}
		let client = Client(serviceURL: URL(string: "pulsar://localhost:6650")!)
		let producer = try client.createProducer(topic: "persistent://public/default/my-topic")
		Task {
			for i in 1 ... 10 {
				let content = "Hello Pulsar \(i)"
				let message = Message(content: "Hello Pulsar \(i)")
				try producer.send(message)
				print("Sent message: \(content)")
				try await Task.sleep(for: .seconds(5))
			}
		}
		let message = Message(content: "Hello Pulsar from async send!")
		try await producer.sendAsync(message)
		let listener = try client.listen(on: "persistent://public/default/my-topic", subscriptionName: "my-subscription")
		var count = 0
		for try await message in listener {
			if count >= 35 {
				break
			}
			print("Received message: \(message.content)")
			try await listener.acknowledgeAsync(message)
			count += 1
		}
		try listener.close()
	}
}

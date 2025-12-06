import Foundation
import Logging
import Pulsar

@main
struct Example {
	static func main() async throws {
		LoggingSystem.bootstrap { label in
			var handler = StreamLogHandler.standardOutput(label: label)
			handler.logLevel = .debug
			return handler
		}
		let client: Client = Client(serviceURL: URL(string: "pulsar://localhost:6650")!)
		let producer: Producer<String> = try client.producer(for: "persistent://public/default/my-topic")
		Task {
			for i in 1 ... 10 {
				let content = "Hello Pulsar \(i)"
				let message = try Message<String>(content: content)
				try await producer.send(message)
				print("Sent message: \(content)")
				try await Task.sleep(for: .seconds(5))
			}
		}

		let message = try Message<String>(content: "Hello Pulsar from async send!")
		try await producer.send(message)
		let listener: Listener<String> = try client.listener(
			on: "persistent://public/default/my-topic",
			subscription: "my-subscription"
		)
		var count = 0
		let consumer: Consumer<String> = try client.consumer(
			for: "persistent://public/default/my-topic",
			subscription: "my-subscription-sync"
		)
		let consumedMessage = try consumer.receive(within: .seconds(10))
		print("Synchronously received message: \(try consumedMessage.content)")
		for try await message in listener {
			if count >= 35 {
				break
			}
			print("Received message: \(try message.content)")
			try await listener.acknowledge(message)
			count += 1
		}
		try listener.close()
	}
}

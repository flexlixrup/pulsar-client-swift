import Avro
import Foundation
import Logging
import Pulsar
import Testing

@Suite("IntegrationTests", .serialized, .disabled(if: ProcessInfo.processInfo.environment["CI"] == "true"))
struct IntegrationTests {

	@AvroSchema
	struct ArrayRecord: PulsarSchema {
		let strings: [String]
	}
	@Test("AvroSchema")
	func avroSchemaTest() throws {

		let client: Client = Client(serviceURL: URL(string: "pulsar://localhost:6650")!)

		let producer: Producer<ArrayRecord> = try client.producer(for: "persistent://public/default/avro-schema-test")
		let message = try Message<ArrayRecord>(content: ArrayRecord(strings: ["one", "two", "three"]))
		try producer.send(message)
		let consumer: Consumer<ArrayRecord> = try client.consumer(
			for: "persistent://public/default/avro-schema-test",
			subscription: "avro-schema-subscription"
		)
		let receivedMessage = try consumer.receive(within: .seconds(10))
		try consumer.close()
		try client.close()
		let content = try receivedMessage.content
		#expect(content.strings == ["one", "two", "three"])
	}

	@Test("StringSchema")
	func stringSchemaTest() throws {
		let client: Client = Client(serviceURL: URL(string: "pulsar://localhost:6650")!)
		let producer: Producer<String> = try client.producer(for: "persistent://public/default/string-schema-test")
		let message = try Message<String>(content: "Hello, Pulsar!")
		try producer.send(message)
		let consumer: Consumer<String> = try client.consumer(
			for: "persistent://public/default/string-schema-test",
			subscription: "string-schema-subscription"
		)
		let receivedMessage = try consumer.receive(within: .seconds(10))
		try consumer.close()
		try client.close()
		let content = try receivedMessage.content
		#expect(content == "Hello, Pulsar!")
	}
}

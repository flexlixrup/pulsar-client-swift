import Avro
import CxxPulsar
import CxxStdlib
import Foundation

extension PulsarSchema where Self: AvroProtocol {

	public var schemaType: PulsarSchemaType {
		.avro
	}
	public var schema: String? {
		get throws {
			try Self.avroSchemaString
		}
	}
	public var schemaInfo: SchemaInfo {
		get throws {
			guard let data = try schema!.data(using: .utf8),
				let name = (try JSONSerialization.jsonObject(with: data) as? [String: Any])?["name"] as? String
			else {
				throw PulsarError.invalidSchema
			}
			return
				SchemaInfo(
					schemaType: .avro,
					name: name,
					schema: try schema,
					properties: [:]
				)
		}
	}

	public func encode() throws -> Data {
		try AvroEncoder(schema: Self.avroSchema).encode(self)
	}
	public static func decode(_ data: Data) throws -> Self {
		try AvroDecoder(schema: Self.avroSchema).decode(Self.self, from: data)
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		guard let schemaString = try? Self.avroSchemaString,
			let data = schemaString.data(using: .utf8),
			let name = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["name"] as? String
		else {
			throw PulsarError.invalidSchema
		}
		return SchemaInfo(
			schemaType: .avro,
			name: name,
			schema: schemaString,
			properties: [:]
		)
	}
}

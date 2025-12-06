import CxxPulsar
import CxxStdlib
import Synchronization

public final class SchemaInfo: Sendable {

	final class Box: @unchecked Sendable {
		var raw: _Pulsar.SchemaInfo
		init(_ raw: _Pulsar.SchemaInfo) { self.raw = raw }
	}

	let schemaType: PulsarSchemaType
	let name: String
	let schema: String?
	let properties: [String: String]
	let state: Mutex<Box>

	init(schemaType: PulsarSchemaType, name: String, schema: String?, properties: [String: String]) {
		self.schemaType = schemaType
		self.name = name
		self.schema = schema
		self.properties = properties
		self.state = Mutex(
			Box(
				_Pulsar.SchemaInfo(
					_Pulsar.SchemaType(Int8(schemaType.rawValue)),
					std.string(name),
					std.string(schema),
					_Pulsar.StringMap()
				)
			)
		)
	}
}

import CxxPulsar
import Foundation

public protocol PulsarSchema: Sendable {
	var schemaType: PulsarSchemaType { get }
	var schema: String? { get throws }
	var schemaInfo: SchemaInfo { get throws }
	func encode() throws -> Data
	static func decode(_ data: Data) throws -> Self
	static func getSchemaInfo() throws -> SchemaInfo
}

public enum PulsarSchemaType: Int32, Sendable {
	case none = 0
	case string = 1
	case json = 2
	case protobuf = 3
	case avro = 4
	case int8 = 6
	case int16 = 7
	case int32 = 8
	case int64 = 9
	case float = 10
	case double = 11
	case keyValue = 15
	case protbufNative = 20
	case bytes = -1
	case autoConsume = -3
	case autoPublish = -4
}

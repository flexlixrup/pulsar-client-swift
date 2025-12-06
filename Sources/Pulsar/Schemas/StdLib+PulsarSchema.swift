import Foundation

// MARK: - String Schema
extension String: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.string
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .string,
				name: "String",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		Data(self.utf8)
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> String {
		guard let string = String(data: data, encoding: .utf8) else {
			throw PulsarError.invalidMessage("Failed to decode String from data: invalid UTF-8 encoding")
		}
		return string
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .string,
			name: "String",
			schema: nil,
			properties: [:]
		)
	}
}

// MARK: - Bool Schema
extension Bool: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.none // Boolean uses BYTES type in C++ client
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .none,
				name: "Boolean",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		var value = self ? UInt8(1) : UInt8(0)
		return Data(bytes: &value, count: 1)
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> Bool {
		guard data.count == 1 else {
			throw PulsarError.invalidMessage("Failed to decode Bool from data: expected 1 byte, got \(data.count) bytes")
		}
		return data[0] != 0
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .none,
			name: "Boolean",
			schema: nil,
			properties: [:]
		)
	}
}

// MARK: - Int8 Schema
extension Int8: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.int8
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .int8,
				name: "INT8",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		var value = self
		return Data(bytes: &value, count: MemoryLayout<Int8>.size)
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> Int8 {
		guard data.count == MemoryLayout<Int8>.size else {
			throw PulsarError.invalidMessage(
				"Failed to decode Int8 from data: expected \(MemoryLayout<Int8>.size) bytes, got \(data.count) bytes"
			)
		}
		return data.withUnsafeBytes { $0.load(as: Int8.self) }
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .int8,
			name: "INT8",
			schema: nil,
			properties: [:]
		)
	}
}

// MARK: - Int16 Schema
extension Int16: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.int16
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .int16,
				name: "INT16",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		var value = self.bigEndian
		return Data(bytes: &value, count: MemoryLayout<Int16>.size)
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> Int16 {
		guard data.count == MemoryLayout<Int16>.size else {
			throw PulsarError.invalidMessage(
				"Failed to decode Int16 from data: expected \(MemoryLayout<Int16>.size) bytes, got \(data.count) bytes"
			)
		}
		return data.withUnsafeBytes { Int16(bigEndian: $0.load(as: Int16.self)) }
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .int16,
			name: "INT16",
			schema: nil,
			properties: [:]
		)
	}
}

// MARK: - Int32 Schema
extension Int32: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.int32
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .int32,
				name: "INT32",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		var value = self.bigEndian
		return Data(bytes: &value, count: MemoryLayout<Int32>.size)
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> Int32 {
		guard data.count == MemoryLayout<Int32>.size else {
			throw PulsarError.invalidMessage(
				"Failed to decode Int32 from data: expected \(MemoryLayout<Int32>.size) bytes, got \(data.count) bytes"
			)
		}
		return data.withUnsafeBytes { Int32(bigEndian: $0.load(as: Int32.self)) }
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .int32,
			name: "INT32",
			schema: nil,
			properties: [:]
		)
	}
}

// MARK: - Int64 Schema
extension Int64: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.int64
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .int64,
				name: "INT64",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		var value = self.bigEndian
		return Data(bytes: &value, count: MemoryLayout<Int64>.size)
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> Int64 {
		guard data.count == MemoryLayout<Int64>.size else {
			throw PulsarError.invalidMessage(
				"Failed to decode Int64 from data: expected \(MemoryLayout<Int64>.size) bytes, got \(data.count) bytes"
			)
		}
		return data.withUnsafeBytes { Int64(bigEndian: $0.load(as: Int64.self)) }
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .int64,
			name: "INT64",
			schema: nil,
			properties: [:]
		)
	}
}

// MARK: - Float Schema
extension Float: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.float
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .float,
				name: "FLOAT",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		var value = self
		return Data(bytes: &value, count: MemoryLayout<Float>.size)
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> Float {
		guard data.count == MemoryLayout<Float>.size else {
			throw PulsarError.invalidMessage(
				"Failed to decode Float from data: expected \(MemoryLayout<Float>.size) bytes, got \(data.count) bytes"
			)
		}
		return data.withUnsafeBytes { $0.load(as: Float.self) }
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .float,
			name: "FLOAT",
			schema: nil,
			properties: [:]
		)
	}
}

// MARK: - Double Schema
extension Double: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.double
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .double,
				name: "DOUBLE",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		var value = self
		return Data(bytes: &value, count: MemoryLayout<Double>.size)
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> Double {
		guard data.count == MemoryLayout<Double>.size else {
			throw PulsarError.invalidMessage(
				"Failed to decode Double from data: expected \(MemoryLayout<Double>.size) bytes, got \(data.count) bytes"
			)
		}
		return data.withUnsafeBytes { $0.load(as: Double.self) }
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .double,
			name: "DOUBLE",
			schema: nil,
			properties: [:]
		)
	}
}

// MARK: - Data (BYTES) Schema
extension Data: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.bytes
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .bytes,
				name: "BYTES",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		self
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> Data {
		data
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .bytes,
			name: "BYTES",
			schema: nil,
			properties: [:]
		)
	}
}

// MARK: - Int Schema (Convenience wrapper for Int64)
extension Int: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.int64
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .int64,
				name: "INT64",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		var value = Int64(self).bigEndian
		return Data(bytes: &value, count: MemoryLayout<Int64>.size)
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> Int {
		guard data.count == MemoryLayout<Int64>.size else {
			throw PulsarError.invalidMessage(
				"Failed to decode Int from data: expected \(MemoryLayout<Int64>.size) bytes, got \(data.count) bytes"
			)
		}
		let int64Value = data.withUnsafeBytes { Int64(bigEndian: $0.load(as: Int64.self)) }
		return Int(int64Value)
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .int64,
			name: "INT64",
			schema: nil,
			properties: [:]
		)
	}
}

// MARK: - UInt Schema (Convenience wrapper for Int64)
extension UInt: PulsarSchema {
	public var schemaType: PulsarSchemaType {
		.int64
	}

	public var schema: String? {
		get throws {
			nil
		}
	}

	public var schemaInfo: SchemaInfo {
		get throws {
			SchemaInfo(
				schemaType: .int64,
				name: "INT64",
				schema: nil,
				properties: [:]
			)
		}
	}

	@inline(__always)
	public func encode() throws -> Data {
		var value = Int64(bitPattern: UInt64(self)).bigEndian
		return Data(bytes: &value, count: MemoryLayout<Int64>.size)
	}

	@inline(__always)
	public static func decode(_ data: Data) throws -> UInt {
		guard data.count == MemoryLayout<Int64>.size else {
			throw PulsarError.invalidMessage(
				"Failed to decode UInt from data: expected \(MemoryLayout<Int64>.size) bytes, got \(data.count) bytes"
			)
		}
		let int64Value = data.withUnsafeBytes { Int64(bigEndian: $0.load(as: Int64.self)) }
		return UInt(bitPattern: Int(int64Value))
	}

	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .int64,
			name: "INT64",
			schema: nil,
			properties: [:]
		)
	}
}

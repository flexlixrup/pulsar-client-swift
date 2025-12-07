import Foundation

// MARK: - String Schema
extension String: PulsarSchema {
	/// The schema type for String.
	public var schemaType: PulsarSchemaType {
		.string
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the string to data.
	@inline(__always)
	public func encode() throws -> Data {
		Data(self.utf8)
	}

	/// Decodes data to a string.
	@inline(__always)
	public static func decode(_ data: Data) throws -> String {
		guard let string = String(data: data, encoding: .utf8) else {
			throw PulsarError.invalidMessage
		}
		return string
	}

	/// Gets the schema information for String.
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
	/// The schema type for Bool.
	public var schemaType: PulsarSchemaType {
		.none // Boolean uses BYTES type in C++ client
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the boolean to data.
	@inline(__always)
	public func encode() throws -> Data {
		var value = self ? UInt8(1) : UInt8(0)
		return Data(bytes: &value, count: 1)
	}

	/// Decodes data to a boolean.
	@inline(__always)
	public static func decode(_ data: Data) throws -> Bool {
		guard data.count == 1 else {
			throw PulsarError.invalidMessage
		}
		return data[0] != 0
	}

	/// Gets the schema information for Bool.
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
	/// The schema type for Int8.
	public var schemaType: PulsarSchemaType {
		.int8
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the Int8 to data.
	@inline(__always)
	public func encode() throws -> Data {
		var value = self
		return Data(bytes: &value, count: MemoryLayout<Int8>.size)
	}

	/// Decodes data to an Int8.
	@inline(__always)
	public static func decode(_ data: Data) throws -> Int8 {
		guard data.count == MemoryLayout<Int8>.size else {
			throw PulsarError.invalidMessage
		}
		return data.withUnsafeBytes { $0.load(as: Int8.self) }
	}

	/// Gets the schema information for Int8.
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
	/// The schema type for Int16.
	public var schemaType: PulsarSchemaType {
		.int16
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the Int16 to data.
	@inline(__always)
	public func encode() throws -> Data {
		var value = self.bigEndian
		return Data(bytes: &value, count: MemoryLayout<Int16>.size)
	}

	/// Decodes data to an Int16.
	@inline(__always)
	public static func decode(_ data: Data) throws -> Int16 {
		guard data.count == MemoryLayout<Int16>.size else {
			throw PulsarError.invalidMessage
		}
		return data.withUnsafeBytes { Int16(bigEndian: $0.load(as: Int16.self)) }
	}

	/// Gets the schema information for Int16.
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
	/// The schema type for Int32.
	public var schemaType: PulsarSchemaType {
		.int32
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the Int32 to data.
	@inline(__always)
	public func encode() throws -> Data {
		var value = self.bigEndian
		return Data(bytes: &value, count: MemoryLayout<Int32>.size)
	}

	/// Decodes data to an Int32.
	@inline(__always)
	public static func decode(_ data: Data) throws -> Int32 {
		guard data.count == MemoryLayout<Int32>.size else {
			throw PulsarError.invalidMessage
		}
		return data.withUnsafeBytes { Int32(bigEndian: $0.load(as: Int32.self)) }
	}

	/// Gets the schema information for Int32.
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
	/// The schema type for Int64.
	public var schemaType: PulsarSchemaType {
		.int64
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the Int64 to data.
	@inline(__always)
	public func encode() throws -> Data {
		var value = self.bigEndian
		return Data(bytes: &value, count: MemoryLayout<Int64>.size)
	}

	/// Decodes data to an Int64.
	@inline(__always)
	public static func decode(_ data: Data) throws -> Int64 {
		guard data.count == MemoryLayout<Int64>.size else {
			throw PulsarError.invalidMessage
		}
		return data.withUnsafeBytes { Int64(bigEndian: $0.load(as: Int64.self)) }
	}

	/// Gets the schema information for Int64.
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
	/// The schema type for Float.
	public var schemaType: PulsarSchemaType {
		.float
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the Float to data.
	@inline(__always)
	public func encode() throws -> Data {
		var value = self
		return Data(bytes: &value, count: MemoryLayout<Float>.size)
	}

	/// Decodes data to a Float.
	@inline(__always)
	public static func decode(_ data: Data) throws -> Float {
		guard data.count == MemoryLayout<Float>.size else {
			throw PulsarError.invalidMessage
		}
		return data.withUnsafeBytes { $0.load(as: Float.self) }
	}

	/// Gets the schema information for Float.
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
	/// The schema type for Double.
	public var schemaType: PulsarSchemaType {
		.double
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the Double to data.
	@inline(__always)
	public func encode() throws -> Data {
		var value = self
		return Data(bytes: &value, count: MemoryLayout<Double>.size)
	}

	/// Decodes data to a Double.
	@inline(__always)
	public static func decode(_ data: Data) throws -> Double {
		guard data.count == MemoryLayout<Double>.size else {
			throw PulsarError.invalidMessage
		}
		return data.withUnsafeBytes { $0.load(as: Double.self) }
	}

	/// Gets the schema information for Double.
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
	/// The schema type for Data.
	public var schemaType: PulsarSchemaType {
		.bytes
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the Data.
	@inline(__always)
	public func encode() throws -> Data {
		self
	}

	/// Decodes data to Data.
	@inline(__always)
	public static func decode(_ data: Data) throws -> Data {
		data
	}

	/// Gets the schema information for Data.
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
	/// The schema type for Int.
	public var schemaType: PulsarSchemaType {
		.int64
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the Int to data.
	@inline(__always)
	public func encode() throws -> Data {
		var value = Int64(self).bigEndian
		return Data(bytes: &value, count: MemoryLayout<Int64>.size)
	}

	/// Decodes data to an Int.
	@inline(__always)
	public static func decode(_ data: Data) throws -> Int {
		guard data.count == MemoryLayout<Int64>.size else {
			throw PulsarError.invalidMessage
		}
		let int64Value = data.withUnsafeBytes { Int64(bigEndian: $0.load(as: Int64.self)) }
		return Int(int64Value)
	}

	/// Gets the schema information for Int.
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
	/// The schema type for UInt.
	public var schemaType: PulsarSchemaType {
		.int64
	}

	/// The schema definition.
	public var schema: String? {
		get throws {
			nil
		}
	}

	/// The schema information.
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

	/// Encodes the UInt to data.
	@inline(__always)
	public func encode() throws -> Data {
		var value = Int64(bitPattern: UInt64(self)).bigEndian
		return Data(bytes: &value, count: MemoryLayout<Int64>.size)
	}

	/// Decodes data to a UInt.
	@inline(__always)
	public static func decode(_ data: Data) throws -> UInt {
		guard data.count == MemoryLayout<Int64>.size else {
			throw PulsarError.invalidMessage
		}
		let int64Value = data.withUnsafeBytes { Int64(bigEndian: $0.load(as: Int64.self)) }
		return UInt(bitPattern: Int(int64Value))
	}

	/// Gets the schema information for UInt.
	public static func getSchemaInfo() throws -> SchemaInfo {
		SchemaInfo(
			schemaType: .int64,
			name: "INT64",
			schema: nil,
			properties: [:]
		)
	}
}

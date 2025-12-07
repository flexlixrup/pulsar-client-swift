import Foundation
import Testing

@testable import Pulsar

@Suite("SchemaUnitTests")
struct SchemaUnitTests {

	@Test("Bool schema encoding/decoding")
	func boolSchema() throws {
		let trueValue = true
		let falseValue = false

		let trueData = try trueValue.encode()
		let falseData = try falseValue.encode()

		#expect(try Bool.decode(trueData) == true)
		#expect(try Bool.decode(falseData) == false)

		let schemaInfo = try Bool.getSchemaInfo()
		#expect(schemaInfo.schemaType == .none)
	}

	@Test("Int8 schema encoding/decoding")
	func int8Schema() throws {
		let value: Int8 = -42
		let data = try value.encode()
		let decoded = try Int8.decode(data)
		#expect(decoded == value)

		let schemaInfo = try Int8.getSchemaInfo()
		#expect(schemaInfo.schemaType == .int8)
	}

	@Test("Int16 schema encoding/decoding")
	func int16Schema() throws {
		let value: Int16 = -1234
		let data = try value.encode()
		let decoded = try Int16.decode(data)
		#expect(decoded == value)

		let schemaInfo = try Int16.getSchemaInfo()
		#expect(schemaInfo.schemaType == .int16)
	}

	@Test("Int32 schema encoding/decoding")
	func int32Schema() throws {
		let value: Int32 = -123456
		let data = try value.encode()
		let decoded = try Int32.decode(data)
		#expect(decoded == value)

		let schemaInfo = try Int32.getSchemaInfo()
		#expect(schemaInfo.schemaType == .int32)
	}

	@Test("Int64 schema encoding/decoding")
	func int64Schema() throws {
		let value: Int64 = -9_876_543_210
		let data = try value.encode()
		let decoded = try Int64.decode(data)
		#expect(decoded == value)

		let schemaInfo = try Int64.getSchemaInfo()
		#expect(schemaInfo.schemaType == .int64)
	}

	@Test("Float schema encoding/decoding")
	func floatSchema() throws {
		let value: Float = 3.14159
		let data = try value.encode()
		let decoded = try Float.decode(data)
		#expect(abs(decoded - value) < 0.00001)

		let schemaInfo = try Float.getSchemaInfo()
		#expect(schemaInfo.schemaType == .float)
	}

	@Test("Double schema encoding/decoding")
	func doubleSchema() throws {
		let value: Double = 3.141592653589793
		let data = try value.encode()
		let decoded = try Double.decode(data)
		#expect(decoded == value)

		let schemaInfo = try Double.getSchemaInfo()
		#expect(schemaInfo.schemaType == .double)
	}

	@Test("Data (BYTES) schema encoding/decoding")
	func dataSchema() throws {
		let value = Data([0x01, 0x02, 0x03, 0x04, 0xFF])
		let data = try value.encode()
		let decoded = try Data.decode(data)
		#expect(decoded == value)

		let schemaInfo = try Data.getSchemaInfo()
		#expect(schemaInfo.schemaType == .bytes)
	}

	@Test("Int convenience wrapper encoding/decoding")
	func intSchema() throws {
		let value: Int = -123_456_789
		let data = try value.encode()
		let decoded = try Int.decode(data)
		#expect(decoded == value)

		let schemaInfo = try Int.getSchemaInfo()
		#expect(schemaInfo.schemaType == .int64)
	}

	@Test("UInt convenience wrapper encoding/decoding")
	func uintSchema() throws {
		let value: UInt = 123_456_789
		let data = try value.encode()
		let decoded = try UInt.decode(data)
		#expect(decoded == value)

		let schemaInfo = try UInt.getSchemaInfo()
		#expect(schemaInfo.schemaType == .int64)
	}
}

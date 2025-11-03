import CxxPulsar
import Foundation
import Testing

@testable import Pulsar

typealias _Pulsar = CxxPulsar.pulsar

@Suite("C++ to Swift Conversions")
struct Conversions {
	@Test("Result enum conversion")
	func resultEnum() {
		let resultRetryable = _Pulsar.Result.init(rawValue: -1) // ResultRetryable
		let swiftResultRetryable = Result(cxx: resultRetryable)
		#expect(swiftResultRetryable == .retryable)

		let resultChecksumError = _Pulsar.Result.init(rawValue: 12) // ResultChecksumError
		let swiftResultChecksumError = Result(cxx: resultChecksumError)
		#expect(swiftResultChecksumError == .checksumError)
	}
}

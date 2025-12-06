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
		let swiftResultRetryable = PulsarResult(cxx: resultRetryable)
		#expect(swiftResultRetryable == .retryable)

		let resultChecksumError = _Pulsar.Result.init(rawValue: 12) // ResultChecksumError
		let swiftResultChecksumError = PulsarResult(cxx: resultChecksumError)
		#expect(swiftResultChecksumError == .checksumError)
	}

	@Test("Test conversion of config")
	func configConversion() {
		let proxyURL = URL(string: "http://proxy.example")!
		let cfg = ClientConfiguration(
			memoryLimit: 12345,
			connectionsPerBroker: 2,
			useTLS: true,
			proxyServiceUrl: proxyURL,
			proxyProtocol: .sni
		)

		let cppConfig = cfg.getConfig()
		#expect(cppConfig.getMemoryLimit() == 12345)
		#expect(cppConfig.getConnectionsPerBroker() == 2)
		#expect(cppConfig.getProxyProtocol() == _Pulsar.ClientConfiguration.ProxyProtocol.init(0)) // SNI
		#expect(cppConfig.isUseTls() == true)
	}
}

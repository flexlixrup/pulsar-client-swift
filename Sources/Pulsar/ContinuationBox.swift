import Logging
import Metrics

final class ContinuationBox: Sendable {
	let cont: CheckedContinuation<Void, Error>
	let logger = Logger(label: "ContinuationBox")

	let counterAll: Counter?
	let counterFailed: Counter?
	let counterSuccess: Counter?

	init(
		_ cont: CheckedContinuation<Void, Error>,
		counterAll: Metrics.Counter? = nil,
		counterFailed: Metrics.Counter? = nil,
		counterSuccess: Metrics.Counter? = nil
	) {
		self.cont = cont
		self.counterAll = counterAll
		self.counterFailed = counterFailed
		self.counterSuccess = counterSuccess
	}

	func checkContinuation(result: Int32, context: String = "Generic") {
		if result == 0 {
			counterSuccess?.increment()
			logger.debug("\(context): Resuming continuation with success")
			cont.resume()
		} else {
			counterFailed?.increment()
			let converted = Result(cxx: _Pulsar.Result(rawValue: result))
			logger.debug("\(context): Resuming continuation with error: \\(converted)")
			cont.resume(throwing: converted)
		}
	}
}

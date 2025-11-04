import Logging

final class ContinuationBox: Sendable {
	let cont: CheckedContinuation<Void, Error>
	let logger = Logger(label: "ContinuationBox")
	init(_ cont: CheckedContinuation<Void, Error>) { self.cont = cont }

	func checkContinuation(result: Int32, context: String = "Generic") {
		if result == 0 {
			logger.debug("\(context): Resuming continuation with success")
			cont.resume()
		} else {
			let converted = Result(cxx: _Pulsar.Result(rawValue: result))
			logger.debug("\(context): Resuming continuation with error: \(converted)")
			cont.resume(throwing: converted)
		}
	}
}

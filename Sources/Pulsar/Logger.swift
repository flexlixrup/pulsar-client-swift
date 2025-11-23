import Bridge
import CxxPulsar
import Foundation
import Logging

struct PulsarLoggerCache: Sendable {
	let logger = Logger(label: "PulsarLoggerCache")
	private var loggers: [String: Logger] = [:]
	var level: Logger.Level
	init() {
		self.level = logger.logLevel
	}
	mutating func logger(for component: String) -> Logger {
		guard let logger = loggers[component] else {
			self.logger.trace("Creating new logger for component: \(component) with level: \(level)")
			let logger = Logger(label: "\(component)")
			level = logger.logLevel
			loggers[component] = logger
			return logger
		}
		self.logger.trace("Reusing existing logger for component: \(component) with level: \(logger.logLevel)")
		return logger
	}
}

final class PulsarLogRegistry: @unchecked Sendable {
	private let lock = NSLock()
	private var _handler: ((Logger.Level, String, Int, String) -> Void)?
	private var cache = PulsarLoggerCache()
	func set(_ handler: ((Logger.Level, String, Int, String) -> Void)?) {
		lock.lock()
		defer { lock.unlock() }
		_handler = handler
	}

	func logger(for component: String) -> Logger {
		lock.lock()
		defer { lock.unlock() }
		return cache.logger(for: component)
	}

	var level: Logger.Level {
		lock.lock()
		defer { lock.unlock() }
		return cache.level
	}

	func call(level: Logger.Level, file: String, line: Int, msg: String) {
		// Copy under lock, call outside lock
		let h: ((Logger.Level, String, Int, String) -> Void)?
		lock.lock()
		h = _handler
		lock.unlock()
		h?(level, file, line, msg)
	}
}

private let _pulsarRegistry = PulsarLogRegistry()

private func mapLevel(_ lvl: Int32) -> Logger.Level {
	switch lvl {
		case 0: return .debug // DEBUG
		case 1: return .info // INFO
		case 2: return .warning // WARN
		default: return .error // ERROR
	}
}
@_cdecl("swift_pulsar_log_handler")
func logHandler(
	_ level: Int32,
	_ file: UnsafePointer<CChar>?,
	_ line: Int32,
	_ message: UnsafePointer<CChar>?
) {
	let lvl = mapLevel(level)
	let fileStr = file.flatMap(String.init(cString:)) ?? ""
	let msg = message.flatMap(String.init(cString:)) ?? ""
	_pulsarRegistry.call(level: lvl, file: fileStr, line: Int(line), msg: msg)
}

func installPulsarLogging(conf: inout _Pulsar.ClientConfiguration) {
	pulsar_swift_set_log_callback(logHandler)
	_pulsarRegistry.set { lvl, file, _, msg in
		_pulsarRegistry.logger(for: file)
			.log(
				level: lvl,
				"\(msg)",
			)
	}

	let minLevelInt: Int32
	switch _pulsarRegistry.level {
		case .trace, .debug: minLevelInt = 0 // DEBUG
		case .info, .notice: minLevelInt = 1 // INFO
		case .warning: minLevelInt = 2 // WARN
		case .error, .critical: minLevelInt = 3 // ERROR
	}

	pulsar_swift_install_logger(&conf, minLevelInt)
}

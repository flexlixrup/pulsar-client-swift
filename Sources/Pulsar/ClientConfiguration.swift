import CxxPulsar
import Foundation
import Logging
import Synchronization

public final class ClientConfiguration: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: _Pulsar.ClientConfiguration
		init(_ raw: _Pulsar.ClientConfiguration) { self.raw = raw }
	}
	private let state: Mutex<Box>
	public let memoryLimit: Int
	public let connectionsPerBroker: Int
	//FIXME: Authentication
	public let operationsTimeout: Duration
	public let ioThreads: Int
	public let messageListenerThreads: Int
	public let concurrentLookupRequest: Int
	public let maxLookupRedirects: Int
	public let initialBackoffInterval: Duration
	public let maxBackoffInterval: Duration
	public let useTLS: Bool
	public let tlsPrivateKeyFilePath: URL?
	public let tlsCertificateFilePath: URL?
	public let tlsTrustCertsFilePath: URL?
	public let tlsAllowInsecureConnection: Bool
	public let tlsHostnameVerificationEnabled: Bool
	public let listenerName: String?
	public let statsInterval: Duration
	public let partitionsUpdateInterval: Duration
	public let connectTimeout: Duration
	public let proxyServiceUrl: URL?
	public let proxyProtocol: ProxyProtocol?
	public let keepAliveInterval: Duration
	let logger = Logger(label: "PulsarImpl")

	public init(
		memoryLimit: Int = 0,
		connectionsPerBroker: Int = 1,
		operationsTimeout: Duration = .seconds(30),
		ioThreads: Int = 1,
		messageListenerThreads: Int = 1,
		concurrentLookupRequest: Int = 50_000,
		maxLookupRedirects: Int = 20,
		initialBackoffInterval: Duration = .milliseconds(100),
		maxBackoffInterval: Duration = .seconds(60),
		useTLS: Bool = false,
		tlsPrivateKeyFilePath: URL? = nil,
		tlsCertificateFilePath: URL? = nil,
		tlsTrustCertsFilePath: URL? = nil,
		tlsAllowInsecureConnection: Bool = false,
		tlsHostnameVerificationEnabled: Bool = false,
		listenerName: String? = nil,
		statsInterval: Duration = .seconds(600),
		partitionsUpdateInterval: Duration = .seconds(60),
		connectTimeout: Duration = .milliseconds(10_000),
		proxyServiceUrl: URL? = nil,
		proxyProtocol: ProxyProtocol? = nil,
		keepAliveInterval: Duration = .seconds(30)
	) {
		self.state = Mutex(Box(_Pulsar.ClientConfiguration()))
		self.memoryLimit = memoryLimit
		self.connectionsPerBroker = connectionsPerBroker
		self.operationsTimeout = operationsTimeout
		self.ioThreads = ioThreads
		self.messageListenerThreads = messageListenerThreads
		self.concurrentLookupRequest = concurrentLookupRequest
		self.maxLookupRedirects = maxLookupRedirects
		self.initialBackoffInterval = initialBackoffInterval
		self.maxBackoffInterval = maxBackoffInterval
		self.useTLS = useTLS
		self.tlsPrivateKeyFilePath = tlsPrivateKeyFilePath
		self.tlsCertificateFilePath = tlsCertificateFilePath
		self.tlsTrustCertsFilePath = tlsTrustCertsFilePath
		self.tlsAllowInsecureConnection = tlsAllowInsecureConnection
		self.tlsHostnameVerificationEnabled = tlsHostnameVerificationEnabled
		self.listenerName = listenerName
		self.statsInterval = statsInterval
		self.partitionsUpdateInterval = partitionsUpdateInterval
		self.connectTimeout = connectTimeout
		self.proxyServiceUrl = proxyServiceUrl
		self.proxyProtocol = proxyProtocol
		self.keepAliveInterval = keepAliveInterval
		setCxxConfig()
	}

	func setCxxConfig() {
		state.withLock { box in
			installPulsarLogging(conf: &box.raw, using: logger)

			// Helpers to convert Swift Duration -> seconds / milliseconds
			@inline(__always)
			func toSeconds(_ d: Duration) -> Int {
				let comps = d.components
				// Round toward zero; Pulsar takes integer seconds
				return Int(comps.seconds)
			}

			@inline(__always)
			func toMilliseconds(_ d: Duration) -> Int {
				let comps = d.components
				// 1 second = 1_000 ms; 1 ms = 1_000_000_000_000_000 attoseconds
				let wholeSecMs = Int(comps.seconds) * 1_000
				let fracMs = Int(comps.attoseconds / 1_000_000_000_000_000)
				return wholeSecMs &+ fracMs
			}

			box.raw.setMemoryLimit(UInt64(memoryLimit))
			box.raw.setConnectionsPerBroker(Int32(connectionsPerBroker))
			box.raw.setOperationTimeoutSeconds(Int32(toSeconds(operationsTimeout)))
			box.raw.setIOThreads(Int32(ioThreads))
			box.raw.setMessageListenerThreads(Int32(messageListenerThreads))

			box.raw.setConcurrentLookupRequest(Int32(concurrentLookupRequest))
			box.raw.setMaxLookupRedirects(Int32(maxLookupRedirects))
			box.raw.setInitialBackoffIntervalMs(Int32(toMilliseconds(initialBackoffInterval)))
			box.raw.setMaxBackoffIntervalMs(Int32(toMilliseconds(maxBackoffInterval)))

			box.raw.setUseTls(useTLS)
			if let key = tlsPrivateKeyFilePath { box.raw.setTlsPrivateKeyFilePath(std.string(key.path)) }
			if let cert = tlsCertificateFilePath { box.raw.setTlsCertificateFilePath(std.string(cert.path)) }
			if let trust = tlsTrustCertsFilePath { box.raw.setTlsTrustCertsFilePath(std.string(trust.path)) }
			box.raw.setTlsAllowInsecureConnection(tlsAllowInsecureConnection)
			box.raw.setValidateHostName(tlsHostnameVerificationEnabled)

			if let name = listenerName, !name.isEmpty {
				box.raw.setListenerName(std.string(name))
			}

			box.raw.setStatsIntervalInSeconds(UInt32(toSeconds(statsInterval)))
			box.raw.setPartititionsUpdateInterval(UInt32(toSeconds(partitionsUpdateInterval)))
			box.raw.setKeepAliveIntervalInSeconds(UInt32(toSeconds(keepAliveInterval)))

			box.raw.setConnectionTimeout(Int32(toMilliseconds(connectTimeout)))

			if let proxy = proxyServiceUrl {
				box.raw.setProxyServiceUrl(std.string(proxy.absoluteString))
			}
			if let proxyProtocol {
				let cxxProto: _Pulsar.ClientConfiguration.ProxyProtocol = .init(
					rawValue: UInt32(proxyProtocol.rawValue)
				)
				box.raw.setProxyProtocol(cxxProto)
			}
		}
	}

	func getConfig() -> _Pulsar.ClientConfiguration {
		state.withLock { box in box.raw }
	}
}

public enum ProxyProtocol: Int, Sendable {
	case sni = 0
}

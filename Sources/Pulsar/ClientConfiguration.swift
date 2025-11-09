import Bridge
import CxxPulsar
import Foundation
import Logging
import Synchronization

public final class ClientConfiguration: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: CxxPulsar.pulsar.ClientConfiguration
		init(_ raw: CxxPulsar.pulsar.ClientConfiguration) { self.raw = raw }
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
		self.state = Mutex(Box(CxxPulsar.pulsar.ClientConfiguration()))
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

			withUnsafeMutablePointer(to: &box.raw) { ptr in
				Bridge_CC_setMemoryLimit(ptr, numericCast(memoryLimit))
				Bridge_CC_setConnectionsPerBroker(ptr, numericCast(connectionsPerBroker))
				Bridge_CC_setOperationTimeoutSeconds(ptr, numericCast(toSeconds(operationsTimeout)))
				Bridge_CC_setIOThreads(ptr, numericCast(ioThreads))
				Bridge_CC_setMessageListenerThreads(ptr, numericCast(messageListenerThreads))

				Bridge_CC_setConcurrentLookupRequest(ptr, numericCast(concurrentLookupRequest))
				Bridge_CC_setMaxLookupRedirects(ptr, numericCast(maxLookupRedirects))
				Bridge_CC_setInitialBackoffIntervalMs(ptr, numericCast(toMilliseconds(initialBackoffInterval)))
				Bridge_CC_setMaxBackoffIntervalMs(ptr, numericCast(toMilliseconds(maxBackoffInterval)))

				Bridge_CC_setUseTls(ptr, useTLS)
				if let key = tlsPrivateKeyFilePath { Bridge_CC_setTlsPrivateKeyFilePath(ptr, key.path) }
				if let cert = tlsCertificateFilePath { Bridge_CC_setTlsCertificateFilePath(ptr, cert.path) }
				if let trust = tlsTrustCertsFilePath { Bridge_CC_setTlsTrustCertsFilePath(ptr, trust.path) }
				Bridge_CC_setTlsAllowInsecureConnection(ptr, tlsAllowInsecureConnection)
				Bridge_CC_setValidateHostName(ptr, tlsHostnameVerificationEnabled)

				if let name = listenerName, !name.isEmpty {
					Bridge_CC_setListenerName(ptr, name)
				}

				Bridge_CC_setStatsIntervalInSeconds(ptr, numericCast(toSeconds(statsInterval)))
				Bridge_CC_setPartitionsUpdateInterval(ptr, numericCast(toSeconds(partitionsUpdateInterval)))
				Bridge_CC_setKeepAliveIntervalInSeconds(ptr, numericCast(toSeconds(keepAliveInterval)))

				Bridge_CC_setConnectionTimeout(ptr, numericCast(toMilliseconds(connectTimeout)))

				if let proxy = proxyServiceUrl {
					Bridge_CC_setProxyServiceUrl(ptr, proxy.absoluteString)
				}
				if let proxyProtocol {
					Bridge_CC_setProxyProtocol(ptr, numericCast(proxyProtocol.rawValue))
				}
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

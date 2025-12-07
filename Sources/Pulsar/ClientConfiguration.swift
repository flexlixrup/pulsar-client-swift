import Bridge
import CxxPulsar
import Foundation
import Logging
import Synchronization

/// Configuration for TLS/SSL connections.
@frozen
public struct TLSConfiguration: Sendable {
	/// Whether TLS is enabled.
	public var enabled: Bool
	/// Path to the private key file.
	public var privateKeyPath: URL?
	/// Path to the certificate file.
	public var certificatePath: URL?
	/// Path to the trusted certificates file.
	public var trustCertsPath: URL?
	/// Whether to allow insecure connections.
	public var allowInsecureConnection: Bool
	/// Whether hostname verification is enabled.
	public var hostnameVerificationEnabled: Bool

	/// Creates a new TLS configuration.
	public init(
		enabled: Bool = false,
		privateKeyPath: URL? = nil,
		certificatePath: URL? = nil,
		trustCertsPath: URL? = nil,
		allowInsecureConnection: Bool = false,
		hostnameVerificationEnabled: Bool = false
	) {
		self.enabled = enabled
		self.privateKeyPath = privateKeyPath
		self.certificatePath = certificatePath
		self.trustCertsPath = trustCertsPath
		self.allowInsecureConnection = allowInsecureConnection
		self.hostnameVerificationEnabled = hostnameVerificationEnabled
	}
}

/// Configuration for backoff retry behavior.
@frozen
public struct BackoffConfiguration: Sendable {
	/// Initial backoff duration.
	public var initial: Duration
	/// Maximum backoff duration.
	public var max: Duration

	/// Creates a new backoff configuration.
	public init(initial: Duration = .milliseconds(100), max: Duration = .seconds(60)) {
		self.initial = initial
		self.max = max
	}
}

/// Configuration for proxy connections.
@frozen
public struct ProxyConfiguration: Sendable {
	/// The proxy service URL.
	public var serviceUrl: URL
	/// The proxy protocol to use.
	public var proxyProtocol: ProxyProtocol

	/// Creates a new proxy configuration.
	public init(serviceUrl: URL, proxyProtocol: ProxyProtocol = .sni) {
		self.serviceUrl = serviceUrl
		self.proxyProtocol = proxyProtocol
	}
}

/// Protocol to use for proxy connections.
@frozen
public enum ProxyProtocol: Int, Sendable {
	case sni = 0
}

/// Configuration for a Pulsar client.
public final class ClientConfiguration: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: CxxPulsar.pulsar.ClientConfiguration
		init(_ raw: CxxPulsar.pulsar.ClientConfiguration) { self.raw = raw }
	}
	private let state: Mutex<Box>

	/// Memory limit in bytes.
	public let memoryLimit: Int
	/// Number of connections per broker.
	public let connectionsPerBroker: Int
	/// Timeout for operations.
	public let operationsTimeout: Duration
	/// Number of I/O threads.
	public let ioThreads: Int
	/// Number of message listener threads.
	public let messageListenerThreads: Int
	/// Maximum number of concurrent lookup requests.
	public let concurrentLookupRequest: Int
	/// Maximum number of lookup redirects.
	public let maxLookupRedirects: Int
	/// Backoff configuration for retries.
	public let backoff: BackoffConfiguration
	/// TLS configuration.
	public let tls: TLSConfiguration
	/// Listener name for broker selection.
	public let listenerName: String?
	/// Interval for collecting statistics.
	public let statsInterval: Duration
	/// Interval for updating partitions.
	public let partitionsUpdateInterval: Duration
	/// Timeout for establishing connections.
	public let connectTimeout: Duration
	/// Proxy configuration.
	public let proxy: ProxyConfiguration?
	/// Interval for keep-alive messages.
	public let keepAliveInterval: Duration

	/// Creates a new client configuration.
	public init(
		memoryLimit: Int = 0,
		connectionsPerBroker: Int = 1,
		operationsTimeout: Duration = .seconds(30),
		ioThreads: Int = 1,
		messageListenerThreads: Int = 1,
		concurrentLookupRequest: Int = 50_000,
		maxLookupRedirects: Int = 20,
		backoff: BackoffConfiguration = BackoffConfiguration(),
		tls: TLSConfiguration = TLSConfiguration(),
		listenerName: String? = nil,
		statsInterval: Duration = .seconds(600),
		partitionsUpdateInterval: Duration = .seconds(60),
		connectTimeout: Duration = .milliseconds(10_000),
		proxy: ProxyConfiguration? = nil,
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
		self.backoff = backoff
		self.tls = tls
		self.listenerName = listenerName
		self.statsInterval = statsInterval
		self.partitionsUpdateInterval = partitionsUpdateInterval
		self.connectTimeout = connectTimeout
		self.proxy = proxy
		self.keepAliveInterval = keepAliveInterval
		setCxxConfig()
	}

	func setCxxConfig() {
		state.withLock { box in
			installPulsarLogging(conf: &box.raw)

			withUnsafeMutablePointer(to: &box.raw) { ptr in
				Bridge_CC_setMemoryLimit(ptr, numericCast(memoryLimit))
				Bridge_CC_setConnectionsPerBroker(ptr, numericCast(connectionsPerBroker))
				Bridge_CC_setOperationTimeoutSeconds(ptr, numericCast(toSeconds(operationsTimeout)))
				Bridge_CC_setIOThreads(ptr, numericCast(ioThreads))
				Bridge_CC_setMessageListenerThreads(ptr, numericCast(messageListenerThreads))

				Bridge_CC_setConcurrentLookupRequest(ptr, numericCast(concurrentLookupRequest))
				Bridge_CC_setMaxLookupRedirects(ptr, numericCast(maxLookupRedirects))
				Bridge_CC_setInitialBackoffIntervalMs(ptr, numericCast(toMilliseconds(backoff.initial)))
				Bridge_CC_setMaxBackoffIntervalMs(ptr, numericCast(toMilliseconds(backoff.max)))

				Bridge_CC_setUseTls(ptr, tls.enabled)
				if let key = tls.privateKeyPath { Bridge_CC_setTlsPrivateKeyFilePath(ptr, key.path) }
				if let cert = tls.certificatePath { Bridge_CC_setTlsCertificateFilePath(ptr, cert.path) }
				if let trust = tls.trustCertsPath { Bridge_CC_setTlsTrustCertsFilePath(ptr, trust.path) }
				Bridge_CC_setTlsAllowInsecureConnection(ptr, tls.allowInsecureConnection)
				Bridge_CC_setValidateHostName(ptr, tls.hostnameVerificationEnabled)

				if let name = listenerName, !name.isEmpty {
					Bridge_CC_setListenerName(ptr, name)
				}

				Bridge_CC_setStatsIntervalInSeconds(ptr, numericCast(toSeconds(statsInterval)))
				Bridge_CC_setPartitionsUpdateInterval(ptr, numericCast(toSeconds(partitionsUpdateInterval)))
				Bridge_CC_setKeepAliveIntervalInSeconds(ptr, numericCast(toSeconds(keepAliveInterval)))

				Bridge_CC_setConnectionTimeout(ptr, numericCast(toMilliseconds(connectTimeout)))

				if let proxy {
					Bridge_CC_setProxyServiceUrl(ptr, proxy.serviceUrl.absoluteString)
					Bridge_CC_setProxyProtocol(ptr, numericCast(proxy.proxyProtocol.rawValue))
				}
			}
		}
	}

	@inline(__always)
	func getConfig() -> _Pulsar.ClientConfiguration {
		state.withLock { box in box.raw }
	}
}

import Bridge
import CxxPulsar
import Foundation
import Logging
import Synchronization

@frozen
public struct TLSConfiguration: Sendable {
	public var enabled: Bool
	public var privateKeyPath: URL?
	public var certificatePath: URL?
	public var trustCertsPath: URL?
	public var allowInsecureConnection: Bool
	public var hostnameVerificationEnabled: Bool

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

@frozen
public struct BackoffConfiguration: Sendable {
	public var initial: Duration
	public var max: Duration

	public init(initial: Duration = .milliseconds(100), max: Duration = .seconds(60)) {
		self.initial = initial
		self.max = max
	}
}

@frozen
public struct ProxyConfiguration: Sendable {
	public var serviceUrl: URL
	public var proxyProtocol: ProxyProtocol

	public init(serviceUrl: URL, proxyProtocol: ProxyProtocol = .sni) {
		self.serviceUrl = serviceUrl
		self.proxyProtocol = proxyProtocol
	}
}

@frozen
public enum ProxyProtocol: Int, Sendable {
	case sni = 0
}

public final class ClientConfiguration: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: CxxPulsar.pulsar.ClientConfiguration
		init(_ raw: CxxPulsar.pulsar.ClientConfiguration) { self.raw = raw }
	}
	private let state: Mutex<Box>

	public let memoryLimit: Int
	public let connectionsPerBroker: Int
	public let authentication: (any AuthenticationMethod)?
	public let operationsTimeout: Duration
	public let ioThreads: Int
	public let messageListenerThreads: Int
	public let concurrentLookupRequest: Int
	public let maxLookupRedirects: Int
	public let backoff: BackoffConfiguration
	public let tls: TLSConfiguration
	public let listenerName: String?
	public let statsInterval: Duration
	public let partitionsUpdateInterval: Duration
	public let connectTimeout: Duration
	public let proxy: ProxyConfiguration?
	public let keepAliveInterval: Duration

	public init(
		memoryLimit: Int = 0,
		connectionsPerBroker: Int = 1,
		authentication: (any AuthenticationMethod)? = nil,
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
		self.authentication = authentication
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

				if let authentication {
					var authPointer = authentication.authPointer._authPointer
					Bridge_CC_setAuthentication(ptr, &authPointer)
				}
			}
		}
	}

	@inline(__always)
	func getConfig() -> _Pulsar.ClientConfiguration {
		state.withLock { box in box.raw }
	}
}

import Bridge
import CxxPulsar
import Foundation
import Synchronization

public enum ConsumerType: Int, Sendable {
	case exclusive = 0
	case shared = 1
	case failover = 2
	case keyShared = 3
}

public enum RegexSubscriptionMode: Int, Sendable {
	case persistentOnly = 0
	case nonPersistentOnly = 1
	case allTopics = 2
}

public enum InitialPosition: Int, Sendable {
	case latest = 0
	case earliest = 1
}

public enum ConsumerCryptoFailureAction: Int, Sendable {
	case fail = 0
	case discard = 1
	case consume = 2
}

public final class ConsumerConfiguration: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: CxxPulsar.pulsar.ConsumerConfiguration
		init(_ raw: CxxPulsar.pulsar.ConsumerConfiguration) { self.raw = raw }
	}
	private let state: Mutex<Box>

	public let consumerType: ConsumerType
	public let receiverQueueSize: Int
	public let maxTotalReceiverQueueSizeAcrossPartitions: Int
	public let name: String?
	public let unAckedMessagesTimeoutMs: UInt64
	public let tickDurationInMs: UInt64
	public let negativeAckRedeliveryDelayMs: Int64
	public let ackGroupingTimeMs: Int64
	public let ackGroupingMaxSize: Int64
	public let brokerConsumerStatsCacheTimeInMs: Int64
	public let cryptoFailureAction: ConsumerCryptoFailureAction
	public let readCompacted: Bool
	public let patternAutoDiscoveryPeriod: Int
	public let regexSubscriptionMode: RegexSubscriptionMode
	public let subscriptionInitialPosition: InitialPosition
	public let replicateSubscriptionStateEnabled: Bool
	public let properties: [String: String]
	public let subscriptionProperties: [String: String]
	public let priorityLevel: Int
	public let maxPendingChunkedMessage: UInt
	public let autoAckOldestChunkedMessageOnQueueFull: Bool
	public let expireTimeOfIncompleteChunkedMessageMs: Int64
	public let startMessageIdInclusive: Bool
	public let enablesBatchIndexAck: Bool
	public let ackReceiptEnabled: Bool
	public let startPaused: Bool

	public init(
		consumerType: ConsumerType = .exclusive,
		receiverQueueSize: Int = 1000,
		maxTotalReceiverQueueSizeAcrossPartitions: Int = 50000,
		name: String? = nil,
		unAckedMessagesTimeoutMs: UInt64 = 0,
		tickDurationInMs: UInt64 = 1000,
		negativeAckRedeliveryDelayMs: Int64 = 60000,
		ackGroupingTimeMs: Int64 = 100,
		ackGroupingMaxSize: Int64 = 1000,
		brokerConsumerStatsCacheTimeInMs: Int64 = 30000,
		cryptoFailureAction: ConsumerCryptoFailureAction = .fail,
		readCompacted: Bool = false,
		patternAutoDiscoveryPeriod: Int = 60,
		regexSubscriptionMode: RegexSubscriptionMode = .persistentOnly,
		subscriptionInitialPosition: InitialPosition = .latest,
		replicateSubscriptionStateEnabled: Bool = false,
		properties: [String: String] = [:],
		subscriptionProperties: [String: String] = [:],
		priorityLevel: Int = 0,
		maxPendingChunkedMessage: UInt = 10,
		autoAckOldestChunkedMessageOnQueueFull: Bool = false,
		expireTimeOfIncompleteChunkedMessageMs: Int64 = 60000,
		startMessageIdInclusive: Bool = false,
		enablesBatchIndexAck: Bool = false,
		ackReceiptEnabled: Bool = false,
		startPaused: Bool = false
	) {
		self.state = Mutex(Box(CxxPulsar.pulsar.ConsumerConfiguration()))
		self.consumerType = consumerType
		self.receiverQueueSize = receiverQueueSize
		self.maxTotalReceiverQueueSizeAcrossPartitions = maxTotalReceiverQueueSizeAcrossPartitions
		self.name = name
		self.unAckedMessagesTimeoutMs = unAckedMessagesTimeoutMs
		self.tickDurationInMs = tickDurationInMs
		self.negativeAckRedeliveryDelayMs = negativeAckRedeliveryDelayMs
		self.ackGroupingTimeMs = ackGroupingTimeMs
		self.ackGroupingMaxSize = ackGroupingMaxSize
		self.brokerConsumerStatsCacheTimeInMs = brokerConsumerStatsCacheTimeInMs
		self.cryptoFailureAction = cryptoFailureAction
		self.readCompacted = readCompacted
		self.patternAutoDiscoveryPeriod = patternAutoDiscoveryPeriod
		self.regexSubscriptionMode = regexSubscriptionMode
		self.subscriptionInitialPosition = subscriptionInitialPosition
		self.replicateSubscriptionStateEnabled = replicateSubscriptionStateEnabled
		self.properties = properties
		self.subscriptionProperties = subscriptionProperties
		self.priorityLevel = priorityLevel
		self.maxPendingChunkedMessage = maxPendingChunkedMessage
		self.autoAckOldestChunkedMessageOnQueueFull = autoAckOldestChunkedMessageOnQueueFull
		self.expireTimeOfIncompleteChunkedMessageMs = expireTimeOfIncompleteChunkedMessageMs
		self.startMessageIdInclusive = startMessageIdInclusive
		self.enablesBatchIndexAck = enablesBatchIndexAck
		self.ackReceiptEnabled = ackReceiptEnabled
		self.startPaused = startPaused
		setCxxConfig()
	}

	func setCxxConfig() {
		state.withLock { box in
			withUnsafeMutablePointer(to: &box.raw) { ptr in
				Bridge_ConsumerConfig_setConsumerType(ptr, numericCast(consumerType.rawValue))
				Bridge_ConsumerConfig_setReceiverQueueSize(ptr, numericCast(receiverQueueSize))
				Bridge_ConsumerConfig_setMaxTotalReceiverQueueSizeAcrossPartitions(
					ptr,
					numericCast(maxTotalReceiverQueueSizeAcrossPartitions)
				)

				if let name = name {
					Bridge_ConsumerConfig_setConsumerName(ptr, name)
				}

				Bridge_ConsumerConfig_setUnAckedMessagesTimeoutMs(ptr, unAckedMessagesTimeoutMs)
				Bridge_ConsumerConfig_setTickDurationInMs(ptr, tickDurationInMs)
				Bridge_ConsumerConfig_setNegativeAckRedeliveryDelayMs(ptr, numericCast(negativeAckRedeliveryDelayMs))
				Bridge_ConsumerConfig_setAckGroupingTimeMs(ptr, numericCast(ackGroupingTimeMs))
				Bridge_ConsumerConfig_setAckGroupingMaxSize(ptr, numericCast(ackGroupingMaxSize))
				Bridge_ConsumerConfig_setBrokerConsumerStatsCacheTimeInMs(ptr, numericCast(brokerConsumerStatsCacheTimeInMs))
				Bridge_ConsumerConfig_setCryptoFailureAction(ptr, numericCast(cryptoFailureAction.rawValue))
				Bridge_ConsumerConfig_setReadCompacted(ptr, readCompacted)
				Bridge_ConsumerConfig_setPatternAutoDiscoveryPeriod(ptr, numericCast(patternAutoDiscoveryPeriod))
				Bridge_ConsumerConfig_setRegexSubscriptionMode(ptr, numericCast(regexSubscriptionMode.rawValue))
				Bridge_ConsumerConfig_setSubscriptionInitialPosition(ptr, numericCast(subscriptionInitialPosition.rawValue))
				Bridge_ConsumerConfig_setReplicateSubscriptionStateEnabled(ptr, replicateSubscriptionStateEnabled)
				Bridge_ConsumerConfig_setPriorityLevel(ptr, numericCast(priorityLevel))
				Bridge_ConsumerConfig_setMaxPendingChunkedMessage(ptr, numericCast(maxPendingChunkedMessage))
				Bridge_ConsumerConfig_setAutoAckOldestChunkedMessageOnQueueFull(ptr, autoAckOldestChunkedMessageOnQueueFull)
				Bridge_ConsumerConfig_setExpireTimeOfIncompleteChunkedMessageMs(
					ptr,
					numericCast(expireTimeOfIncompleteChunkedMessageMs)
				)
				Bridge_ConsumerConfig_setStartMessageIdInclusive(ptr, startMessageIdInclusive)
				Bridge_ConsumerConfig_setBatchIndexAckEnabled(ptr, enablesBatchIndexAck)
				Bridge_ConsumerConfig_setAckReceiptEnabled(ptr, ackReceiptEnabled)
				Bridge_ConsumerConfig_setStartPaused(ptr, startPaused)

				for (name, value) in properties {
					Bridge_ConsumerConfig_setProperty(ptr, name, value)
				}
			}
		}
	}

	func setCxxSchema<T: PulsarSchema>(_ schema: T.Type) throws {
		let schemaInfo = try T.getSchemaInfo()
		state.withLock { box in
			schemaInfo.state.withLock { schemaBox in
				withUnsafeMutablePointer(to: &box.raw) { configPtr in
					withUnsafePointer(to: &schemaBox.raw) { schemaPtr in
						Bridge_ConsumerConfig_setSchema(configPtr, schemaPtr)
					}
				}
			}
		}
	}

	func getConfig() -> _Pulsar.ConsumerConfiguration {
		state.withLock { box in box.raw }
	}
}

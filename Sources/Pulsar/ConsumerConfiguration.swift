import Bridge
import CxxPulsar
import Foundation
import Synchronization

@frozen
public enum ConsumerType: Int, Sendable {
	case exclusive = 0
	case shared = 1
	case failover = 2
	case keyShared = 3
}

@frozen
public enum RegexSubscriptionMode: Int, Sendable {
	case persistentOnly = 0
	case nonPersistentOnly = 1
	case all = 2
}

@frozen
public enum InitialPosition: Int, Sendable {
	case latest = 0
	case earliest = 1
}

@frozen
public enum CryptoFailureAction: Int, Sendable {
	case fail = 0
	case discard = 1
	case consume = 2
}

@frozen
public struct AcknowledgmentConfiguration: Sendable {
	public var unackedTimeout: Duration
	public var tickDuration: Duration
	public var negativeRedeliveryDelay: Duration
	public var groupingTime: Duration
	public var groupingMaxSize: Int64
	public var receiptEnabled: Bool
	public var batchIndexEnabled: Bool

	public init(
		unackedTimeout: Duration = .zero,
		tickDuration: Duration = .seconds(1),
		negativeRedeliveryDelay: Duration = .seconds(60),
		groupingTime: Duration = .milliseconds(100),
		groupingMaxSize: Int64 = 1000,
		receiptEnabled: Bool = false,
		batchIndexEnabled: Bool = false
	) {
		self.unackedTimeout = unackedTimeout
		self.tickDuration = tickDuration
		self.negativeRedeliveryDelay = negativeRedeliveryDelay
		self.groupingTime = groupingTime
		self.groupingMaxSize = groupingMaxSize
		self.receiptEnabled = receiptEnabled
		self.batchIndexEnabled = batchIndexEnabled
	}
}

@frozen
public struct ChunkedMessageConfiguration: Sendable {
	public var maxPending: UInt
	public var autoAckOldestOnQueueFull: Bool
	public var expireTimeOfIncomplete: Duration

	public init(
		maxPending: UInt = 10,
		autoAckOldestOnQueueFull: Bool = false,
		expireTimeOfIncomplete: Duration = .seconds(60)
	) {
		self.maxPending = maxPending
		self.autoAckOldestOnQueueFull = autoAckOldestOnQueueFull
		self.expireTimeOfIncomplete = expireTimeOfIncomplete
	}
}

public final class ConsumerConfiguration: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: CxxPulsar.pulsar.ConsumerConfiguration
		init(_ raw: CxxPulsar.pulsar.ConsumerConfiguration) { self.raw = raw }
	}
	private let state: Mutex<Box>

	public let type: ConsumerType
	public let receiverQueueSize: Int
	public let maxTotalReceiverQueueSizeAcrossPartitions: Int
	public let name: String?
	public let acknowledgment: AcknowledgmentConfiguration
	public let brokerConsumerStatsCacheTime: Duration
	public let cryptoFailureAction: CryptoFailureAction
	public let readCompacted: Bool
	public let patternAutoDiscoveryPeriod: Int
	public let regexSubscriptionMode: RegexSubscriptionMode
	public let subscriptionInitialPosition: InitialPosition
	public let replicateSubscriptionStateEnabled: Bool
	public let properties: [String: String]
	public let subscriptionProperties: [String: String]
	public let priorityLevel: Int
	public let chunkedMessage: ChunkedMessageConfiguration
	public let startMessageIdInclusive: Bool
	public let startPaused: Bool

	public init(
		type: ConsumerType = .exclusive,
		receiverQueueSize: Int = 1000,
		maxTotalReceiverQueueSizeAcrossPartitions: Int = 50000,
		name: String? = nil,
		acknowledgment: AcknowledgmentConfiguration = AcknowledgmentConfiguration(),
		brokerConsumerStatsCacheTime: Duration = .seconds(30),
		cryptoFailureAction: CryptoFailureAction = .fail,
		readCompacted: Bool = false,
		patternAutoDiscoveryPeriod: Int = 60,
		regexSubscriptionMode: RegexSubscriptionMode = .persistentOnly,
		subscriptionInitialPosition: InitialPosition = .latest,
		replicateSubscriptionStateEnabled: Bool = false,
		properties: [String: String] = [:],
		subscriptionProperties: [String: String] = [:],
		priorityLevel: Int = 0,
		chunkedMessage: ChunkedMessageConfiguration = ChunkedMessageConfiguration(),
		startMessageIdInclusive: Bool = false,
		startPaused: Bool = false
	) {
		self.state = Mutex(Box(CxxPulsar.pulsar.ConsumerConfiguration()))
		self.type = type
		self.receiverQueueSize = receiverQueueSize
		self.maxTotalReceiverQueueSizeAcrossPartitions = maxTotalReceiverQueueSizeAcrossPartitions
		self.name = name
		self.acknowledgment = acknowledgment
		self.brokerConsumerStatsCacheTime = brokerConsumerStatsCacheTime
		self.cryptoFailureAction = cryptoFailureAction
		self.readCompacted = readCompacted
		self.patternAutoDiscoveryPeriod = patternAutoDiscoveryPeriod
		self.regexSubscriptionMode = regexSubscriptionMode
		self.subscriptionInitialPosition = subscriptionInitialPosition
		self.replicateSubscriptionStateEnabled = replicateSubscriptionStateEnabled
		self.properties = properties
		self.subscriptionProperties = subscriptionProperties
		self.priorityLevel = priorityLevel
		self.chunkedMessage = chunkedMessage
		self.startMessageIdInclusive = startMessageIdInclusive
		self.startPaused = startPaused
		setCxxConfig()
	}
	func setCxxConfig() {
		state.withLock { box in
			withUnsafeMutablePointer(to: &box.raw) { ptr in
				Bridge_ConsumerConfig_setConsumerType(ptr, numericCast(type.rawValue))
				Bridge_ConsumerConfig_setReceiverQueueSize(ptr, numericCast(receiverQueueSize))
				Bridge_ConsumerConfig_setMaxTotalReceiverQueueSizeAcrossPartitions(
					ptr,
					numericCast(maxTotalReceiverQueueSizeAcrossPartitions)
				)

				if let name = name {
					Bridge_ConsumerConfig_setConsumerName(ptr, name)
				}

				Bridge_ConsumerConfig_setUnAckedMessagesTimeoutMs(ptr, numericCast(toMilliseconds(acknowledgment.unackedTimeout)))
				Bridge_ConsumerConfig_setTickDurationInMs(ptr, numericCast(toMilliseconds(acknowledgment.tickDuration)))
				Bridge_ConsumerConfig_setNegativeAckRedeliveryDelayMs(
					ptr,
					numericCast(toMilliseconds(acknowledgment.negativeRedeliveryDelay))
				)
				Bridge_ConsumerConfig_setAckGroupingTimeMs(ptr, numericCast(toMilliseconds(acknowledgment.groupingTime)))
				Bridge_ConsumerConfig_setAckGroupingMaxSize(ptr, numericCast(acknowledgment.groupingMaxSize))
				Bridge_ConsumerConfig_setBrokerConsumerStatsCacheTimeInMs(
					ptr,
					numericCast(toMilliseconds(brokerConsumerStatsCacheTime))
				)
				Bridge_ConsumerConfig_setCryptoFailureAction(ptr, numericCast(cryptoFailureAction.rawValue))
				Bridge_ConsumerConfig_setReadCompacted(ptr, readCompacted)
				Bridge_ConsumerConfig_setPatternAutoDiscoveryPeriod(ptr, numericCast(patternAutoDiscoveryPeriod))
				Bridge_ConsumerConfig_setRegexSubscriptionMode(ptr, numericCast(regexSubscriptionMode.rawValue))
				Bridge_ConsumerConfig_setSubscriptionInitialPosition(ptr, numericCast(subscriptionInitialPosition.rawValue))
				Bridge_ConsumerConfig_setReplicateSubscriptionStateEnabled(ptr, replicateSubscriptionStateEnabled)
				Bridge_ConsumerConfig_setPriorityLevel(ptr, numericCast(priorityLevel))
				Bridge_ConsumerConfig_setMaxPendingChunkedMessage(ptr, numericCast(chunkedMessage.maxPending))
				Bridge_ConsumerConfig_setAutoAckOldestChunkedMessageOnQueueFull(ptr, chunkedMessage.autoAckOldestOnQueueFull)
				Bridge_ConsumerConfig_setExpireTimeOfIncompleteChunkedMessageMs(
					ptr,
					numericCast(toMilliseconds(chunkedMessage.expireTimeOfIncomplete))
				)
				Bridge_ConsumerConfig_setStartMessageIdInclusive(ptr, startMessageIdInclusive)
				Bridge_ConsumerConfig_setBatchIndexAckEnabled(ptr, acknowledgment.batchIndexEnabled)
				Bridge_ConsumerConfig_setAckReceiptEnabled(ptr, acknowledgment.receiptEnabled)
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

	@inline(__always)
	func getConfig() -> _Pulsar.ConsumerConfiguration {
		state.withLock { box in box.raw }
	}
}

import Bridge
import CxxPulsar
import Foundation
import Synchronization

/// Type of consumer subscription.
@frozen
public enum ConsumerType: Int, Sendable {
	case exclusive = 0
	case shared = 1
	case failover = 2
	case keyShared = 3
}

/// Mode for regex-based topic subscriptions.
@frozen
public enum RegexSubscriptionMode: Int, Sendable {
	case persistentOnly = 0
	case nonPersistentOnly = 1
	case all = 2
}

/// Initial position in the topic for a new subscription.
@frozen
public enum InitialPosition: Int, Sendable {
	case latest = 0
	case earliest = 1
}

/// Action to take when message decryption fails.
@frozen
public enum CryptoFailureAction: Int, Sendable {
	case fail = 0
	case discard = 1
	case consume = 2
}

/// Configuration for message acknowledgment behavior.
@frozen
public struct AcknowledgmentConfiguration: Sendable {
	/// Timeout for unacknowledged messages.
	public var unackedTimeout: Duration
	/// Duration of each tick for timeout checks.
	public var tickDuration: Duration
	/// Delay before redelivering negatively acknowledged messages.
	public var negativeRedeliveryDelay: Duration
	/// Time to group acknowledgments.
	public var groupingTime: Duration
	/// Maximum number of acknowledgments to group.
	public var groupingMaxSize: Int64
	/// Whether acknowledgment receipts are enabled.
	public var receiptEnabled: Bool
	/// Whether batch index acknowledgment is enabled.
	public var batchIndexEnabled: Bool

	/// Creates a new acknowledgment configuration.
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

/// Configuration for handling chunked messages.
@frozen
public struct ChunkedMessageConfiguration: Sendable {
	/// Maximum number of pending chunked messages.
	public var maxPending: UInt
	/// Whether to auto-acknowledge oldest message when queue is full.
	public var autoAckOldestOnQueueFull: Bool
	/// Expiration time for incomplete chunked messages.
	public var expireTimeOfIncomplete: Duration

	/// Creates a new chunked message configuration.
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

/// Configuration for a Pulsar consumer.
public final class ConsumerConfiguration: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: CxxPulsar.pulsar.ConsumerConfiguration
		init(_ raw: CxxPulsar.pulsar.ConsumerConfiguration) { self.raw = raw }
	}
	private let state: Mutex<Box>

	/// The consumer type.
	public let type: ConsumerType
	/// Size of the receiver queue.
	public let receiverQueueSize: Int
	/// Maximum total receiver queue size across partitions.
	public let maxTotalReceiverQueueSizeAcrossPartitions: Int
	/// Consumer name.
	public let name: String?
	/// Acknowledgment configuration.
	public let acknowledgment: AcknowledgmentConfiguration
	/// Cache time for broker consumer statistics.
	public let brokerConsumerStatsCacheTime: Duration
	/// Action to take on crypto failures.
	public let cryptoFailureAction: CryptoFailureAction
	/// Whether to read compacted topics.
	public let readCompacted: Bool
	/// Period for pattern auto-discovery in seconds.
	public let patternAutoDiscoveryPeriod: Int
	/// Regex subscription mode.
	public let regexSubscriptionMode: RegexSubscriptionMode
	/// Initial position for the subscription.
	public let subscriptionInitialPosition: InitialPosition
	/// Whether subscription state replication is enabled.
	public let replicateSubscriptionStateEnabled: Bool
	/// Custom properties for the consumer.
	public let properties: [String: String]
	/// Custom properties for the subscription.
	public let subscriptionProperties: [String: String]
	/// Priority level for the consumer.
	public let priorityLevel: Int
	/// Chunked message configuration.
	public let chunkedMessage: ChunkedMessageConfiguration
	/// Whether the start message ID is inclusive.
	public let startMessageIdInclusive: Bool
	/// Whether the consumer starts in paused state.
	public let startPaused: Bool

	/// Creates a new consumer configuration.
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

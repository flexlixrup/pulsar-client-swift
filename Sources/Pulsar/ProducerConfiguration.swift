import Bridge
import CxxPulsar
import Foundation
import Synchronization

/// Mode for routing messages to partitions.
@frozen
public enum PartitionsRoutingMode: Int, Sendable {
	case singlePartition = 0
	case roundRobin = 1
	case custom = 2
}

/// Hashing scheme for message routing.
@frozen
public enum HashingScheme: Int, Sendable {
	case murmur32 = 0
	case boost = 1
	case javaString = 2
}

/// Compression type for messages.
@frozen
public enum CompressionType: Int, Sendable {
	case none = 0
	case lz4 = 1
	case zlib = 2
	case zstd = 3
	case snappy = 4
}

/// Access mode for producer.
@frozen
public enum ProducerAccessMode: Int, Sendable {
	case shared = 0
	case exclusive = 1
	case waitForExclusive = 2
	case exclusiveWithFencing = 3
}

/// Configuration for message batching.
@frozen
public struct BatchingConfiguration: Sendable {
	/// Maximum number of messages in a batch.
	public var maxMessages: UInt
	/// Maximum size of a batch in bytes.
	public var maxSize: UInt
	/// Maximum delay for batching.
	public var maxDelay: Duration
	/// Type of batching to use.
	public var type: BatchingType

	/// Type of batching.
	@frozen
	public enum BatchingType: Int, Sendable {
		case `default` = 0
		case keyBased = 1
	}

	/// Creates a new batching configuration.
	public init(
		maxMessages: UInt = 1000,
		maxSize: UInt = 128 * 1024,
		maxDelay: Duration = .milliseconds(10),
		type: BatchingType = .default
	) {
		self.maxMessages = maxMessages
		self.maxSize = maxSize
		self.maxDelay = maxDelay
		self.type = type
	}
}

/// Configuration for a Pulsar producer.
public final class ProducerConfiguration: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: CxxPulsar.pulsar.ProducerConfiguration
		init(_ raw: CxxPulsar.pulsar.ProducerConfiguration) { self.raw = raw }
	}
	private let state: Mutex<Box>

	/// Producer name.
	public let name: String?
	/// Timeout for send operations.
	public let sendTimeout: Duration
	/// Initial sequence ID for messages.
	public let initialSequenceId: Int64
	/// Compression type to use.
	public let compression: CompressionType
	/// Maximum number of pending messages.
	public let maxPendingMessages: Int
	/// Maximum pending messages across partitions.
	public let maxPendingMessagesAcrossPartitions: Int
	/// Routing mode for partitioned topics.
	public let routingMode: PartitionsRoutingMode
	/// Hashing scheme for routing.
	public let hashingScheme: HashingScheme
	/// Whether to lazily start partitioned producers.
	public let lazyStartPartitionedProducers: Bool
	/// Whether to block when queue is full.
	public let blockIfQueueFull: Bool
	/// Batching configuration, or nil to disable batching.
	public let batching: BatchingConfiguration?
	/// Whether to enable chunking for large messages.
	public let chunking: Bool
	/// Access mode for the producer.
	public let accessMode: ProducerAccessMode
	/// Custom properties for the producer.
	public let properties: [String: String]

	/// Creates a new producer configuration.
	public init(
		name: String? = nil,
		sendTimeout: Duration = .seconds(30),
		initialSequenceId: Int64 = -1,
		compression: CompressionType = .none,
		maxPendingMessages: Int = 1000,
		maxPendingMessagesAcrossPartitions: Int = 50000,
		routingMode: PartitionsRoutingMode = .roundRobin,
		hashingScheme: HashingScheme = .boost,
		lazyStartPartitionedProducers: Bool = false,
		blockIfQueueFull: Bool = false,
		batching: BatchingConfiguration? = BatchingConfiguration(),
		chunking: Bool = false,
		accessMode: ProducerAccessMode = .shared,
		properties: [String: String] = [:]
	) {
		self.state = Mutex(Box(CxxPulsar.pulsar.ProducerConfiguration()))
		self.name = name
		self.sendTimeout = sendTimeout
		self.initialSequenceId = initialSequenceId
		self.compression = compression
		self.maxPendingMessages = maxPendingMessages
		self.maxPendingMessagesAcrossPartitions = maxPendingMessagesAcrossPartitions
		self.routingMode = routingMode
		self.hashingScheme = hashingScheme
		self.lazyStartPartitionedProducers = lazyStartPartitionedProducers
		self.blockIfQueueFull = blockIfQueueFull
		self.batching = batching
		self.chunking = chunking
		self.accessMode = accessMode
		self.properties = properties
		setCxxConfig()
	}

	func setCxxConfig() {
		state.withLock { box in
			withUnsafeMutablePointer(to: &box.raw) { ptr in
				if let name = name {
					Bridge_PC_setProducerName(ptr, name)
				}

				Bridge_PC_setSendTimeout(ptr, numericCast(toMilliseconds(sendTimeout)))
				Bridge_PC_setInitialSequenceId(ptr, initialSequenceId)
				Bridge_PC_setCompressionType(ptr, numericCast(compression.rawValue))
				Bridge_PC_setMaxPendingMessages(ptr, numericCast(maxPendingMessages))
				Bridge_PC_setMaxPendingMessagesAcrossPartitions(ptr, numericCast(maxPendingMessagesAcrossPartitions))
				Bridge_PC_setPartitionsRoutingMode(ptr, numericCast(routingMode.rawValue))
				Bridge_PC_setHashingScheme(ptr, numericCast(hashingScheme.rawValue))
				Bridge_PC_setLazyStartPartitionedProducers(ptr, lazyStartPartitionedProducers)
				Bridge_PC_setBlockIfQueueFull(ptr, blockIfQueueFull)

				if let batching = batching {
					Bridge_PC_setBatchingEnabled(ptr, true)
					Bridge_PC_setBatchingMaxMessages(ptr, numericCast(batching.maxMessages))
					Bridge_PC_setBatchingMaxAllowedSizeInBytes(ptr, numericCast(batching.maxSize))
					Bridge_PC_setBatchingMaxPublishDelayMs(ptr, numericCast(toMilliseconds(batching.maxDelay)))
					Bridge_PC_setBatchingType(ptr, numericCast(batching.type.rawValue))
				} else {
					Bridge_PC_setBatchingEnabled(ptr, false)
				}

				Bridge_PC_setChunkingEnabled(ptr, chunking)
				Bridge_PC_setAccessMode(ptr, numericCast(accessMode.rawValue))

				for (name, value) in properties {
					Bridge_PC_setProperty(ptr, name, value)
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
						Bridge_PC_setSchema(configPtr, schemaPtr)
					}
				}
			}
		}
	}

	@inline(__always)
	func getConfig() -> _Pulsar.ProducerConfiguration {
		state.withLock { box in box.raw }
	}
}

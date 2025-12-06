import Bridge
import CxxPulsar
import Foundation
import Synchronization

public enum PartitionsRoutingMode: Int, Sendable {
	case useSinglePartition = 0
	case roundRobinDistribution = 1
	case customPartition = 2
}

public enum HashingScheme: Int, Sendable {
	case murmur32Hash = 0
	case boostHash = 1
	case javaStringHash = 2
}

public enum BatchingType: Int, Sendable {
	case defaultBatching = 0
	case keyBased = 1
}

public enum ProducerAccessMode: Int, Sendable {
	case shared = 0
	case exclusive = 1
	case waitForExclusive = 2
	case exclusiveWithFencing = 3
}

public enum CompressionType: Int, Sendable {
	case none = 0
	case lz4 = 1
	case zlib = 2
	case zstd = 3
	case snappy = 4
}

public final class ProducerConfiguration: Sendable {
	// We have this safely synchronized via the Mutex
	final class Box: @unchecked Sendable {
		var raw: CxxPulsar.pulsar.ProducerConfiguration
		init(_ raw: CxxPulsar.pulsar.ProducerConfiguration) { self.raw = raw }
	}
	private let state: Mutex<Box>

	public let name: String?
	public let sendTimeout: Duration
	public let initialSequenceId: Int64
	public let compressionType: CompressionType
	public let maxPendingMessages: Int
	public let maxPendingMessagesAcrossPartitions: Int
	public let partitionsRoutingMode: PartitionsRoutingMode
	public let hashingScheme: HashingScheme
	public let lazyStartPartitionedProducers: Bool
	public let blockIfQueueFull: Bool
	public let enablesBatching: Bool
	public let batchingMaxMessages: UInt
	public let batchingMaxAllowedSizeInBytes: UInt
	public let batchingMaxPublishDelayMs: UInt
	public let batchingType: BatchingType
	public let enablesChunking: Bool
	public let accessMode: ProducerAccessMode
	public let properties: [String: String]

	public init(
		name: String? = nil,
		sendTimeout: Duration = .seconds(30),
		initialSequenceId: Int64 = -1,
		compressionType: CompressionType = .none,
		maxPendingMessages: Int = 1000,
		maxPendingMessagesAcrossPartitions: Int = 50000,
		partitionsRoutingMode: PartitionsRoutingMode = .roundRobinDistribution,
		hashingScheme: HashingScheme = .boostHash,
		lazyStartPartitionedProducers: Bool = false,
		blockIfQueueFull: Bool = false,
		enablesBatching: Bool = true,
		batchingMaxMessages: UInt = 1000,
		batchingMaxAllowedSizeInBytes: UInt = 131072, // 128 KB
		batchingMaxPublishDelayMs: UInt = 10,
		batchingType: BatchingType = .defaultBatching,
		enablesChunking: Bool = false,
		accessMode: ProducerAccessMode = .shared,
		properties: [String: String] = [:]
	) {
		self.state = Mutex(Box(CxxPulsar.pulsar.ProducerConfiguration()))
		self.name = name
		self.sendTimeout = sendTimeout
		self.initialSequenceId = initialSequenceId
		self.compressionType = compressionType
		self.maxPendingMessages = maxPendingMessages
		self.maxPendingMessagesAcrossPartitions = maxPendingMessagesAcrossPartitions
		self.partitionsRoutingMode = partitionsRoutingMode
		self.hashingScheme = hashingScheme
		self.lazyStartPartitionedProducers = lazyStartPartitionedProducers
		self.blockIfQueueFull = blockIfQueueFull
		self.enablesBatching = enablesBatching
		self.batchingMaxMessages = batchingMaxMessages
		self.batchingMaxAllowedSizeInBytes = batchingMaxAllowedSizeInBytes
		self.batchingMaxPublishDelayMs = batchingMaxPublishDelayMs
		self.batchingType = batchingType
		self.enablesChunking = enablesChunking
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
				Bridge_PC_setCompressionType(ptr, numericCast(compressionType.rawValue))
				Bridge_PC_setMaxPendingMessages(ptr, numericCast(maxPendingMessages))
				Bridge_PC_setMaxPendingMessagesAcrossPartitions(ptr, numericCast(maxPendingMessagesAcrossPartitions))
				Bridge_PC_setPartitionsRoutingMode(ptr, numericCast(partitionsRoutingMode.rawValue))
				Bridge_PC_setHashingScheme(ptr, numericCast(hashingScheme.rawValue))
				Bridge_PC_setLazyStartPartitionedProducers(ptr, lazyStartPartitionedProducers)
				Bridge_PC_setBlockIfQueueFull(ptr, blockIfQueueFull)
				Bridge_PC_setBatchingEnabled(ptr, enablesBatching)
				Bridge_PC_setBatchingMaxMessages(ptr, numericCast(batchingMaxMessages))
				Bridge_PC_setBatchingMaxAllowedSizeInBytes(ptr, numericCast(batchingMaxAllowedSizeInBytes))
				Bridge_PC_setBatchingMaxPublishDelayMs(ptr, numericCast(batchingMaxPublishDelayMs))
				Bridge_PC_setBatchingType(ptr, numericCast(batchingType.rawValue))
				Bridge_PC_setChunkingEnabled(ptr, enablesChunking)
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

	func getConfig() -> _Pulsar.ProducerConfiguration {
		state.withLock { box in box.raw }
	}
}

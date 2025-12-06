import Bridge
import CxxPulsar
import Foundation
import Synchronization

@frozen
public enum PartitionsRoutingMode: Int, Sendable {
	case singlePartition = 0
	case roundRobin = 1
	case custom = 2
}

@frozen
public enum HashingScheme: Int, Sendable {
	case murmur32 = 0
	case boost = 1
	case javaString = 2
}

@frozen
public enum CompressionType: Int, Sendable {
	case none = 0
	case lz4 = 1
	case zlib = 2
	case zstd = 3
	case snappy = 4
}

@frozen
public enum ProducerAccessMode: Int, Sendable {
	case shared = 0
	case exclusive = 1
	case waitForExclusive = 2
	case exclusiveWithFencing = 3
}

@frozen
public struct BatchingConfiguration: Sendable {
	public var maxMessages: UInt
	public var maxSize: UInt
	public var maxDelay: Duration
	public var type: BatchingType

	@frozen
	public enum BatchingType: Int, Sendable {
		case `default` = 0
		case keyBased = 1
	}

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
	public let compression: CompressionType
	public let maxPendingMessages: Int
	public let maxPendingMessagesAcrossPartitions: Int
	public let routingMode: PartitionsRoutingMode
	public let hashingScheme: HashingScheme
	public let lazyStartPartitionedProducers: Bool
	public let blockIfQueueFull: Bool
	public let batching: BatchingConfiguration?
	public let chunking: Bool
	public let accessMode: ProducerAccessMode
	public let properties: [String: String]

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

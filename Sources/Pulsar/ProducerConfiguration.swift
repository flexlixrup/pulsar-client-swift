import CxxPulsar

public enum PartitionsRoutingMode {
	case useSinglePartition
	case roundRobinDistribution
	case customPartition
}

public enum HashingScheme {
	case javaStringHash
	case murmur3_32Hash
	case boostHash
}

public enum BatchingType {
	case defaultBatching
	case keyBased
}

public enum ProducerAccessMode: Int {
	case shared = 0
	case exclusive = 1
	case waitForExclusive = 2
	case exclusiveWithFencing = 3
}

// public struct ProducerConfiguration {
// 	var config = _Pulsar.ProducerConfiguration
// 	public let producerName: String
// 	// FIXME: Schema
// }

import CxxPulsar

public enum PartitionsRoutingMode {
	case UseSinglePartition
	case RoundRobinDistribution
	case CustomPartition
}

public enum HashingScheme {
	case JavaStringHash
	case Murmur3_32Hash
	case BoostHash
}

public enum BatchingType {
	case Default
	case KeyBased
}

public enum ProducerAccessMode: Int {
	case Shared = 0
	case Exclusive = 1
	case WaitForExclusive = 2
	case ExclusiveWithFencing = 3
}

// public struct ProducerConfiguration {
// 	var config = _Pulsar.ProducerConfiguration
// 	public let producerName: String
// 	// FIXME: Schema
// }

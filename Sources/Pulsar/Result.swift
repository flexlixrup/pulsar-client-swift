import Foundation

/// Result codes returned by Pulsar operations.
@frozen
public enum PulsarError: Int, Error, CustomStringConvertible, Sendable {
	/// An internal error code used for retry
	case retryable = -1
	/// Operation completed successfully
	/// Not used just kept for compatibility with C++ enum
	case ok = 0
	/// Unknown error happened on broker
	case unknownError
	/// Invalid configuration
	case invalidConfiguration
	/// Operation timed out
	case timeout
	/// Broker lookup failed
	case lookupError
	/// Failed to connect to broker
	case connectError
	/// Failed to read from socket
	case readError
	/// Authentication failed on broker
	case authenticationError
	/// Client not authorized to create producer/consumer
	case authorizationError
	/// Client cannot find authorization data
	case errorGettingAuthenticationData
	/// Broker failed in updating metadata
	case brokerMetadataError
	/// Broker failed to persist entry
	case brokerPersistenceError
	/// Corrupt message checksum failure
	case checksumError
	/// Exclusive consumer is already connected
	case consumerBusy
	/// Producer/Consumer is not currently connected to broker
	case notConnected
	/// Producer/Consumer is already closed and not accepting any operation
	case alreadyClosed
	/// Error in publishing an already used message
	case invalidMessage
	/// Consumer is not initialized
	case consumerNotInitialized
	/// Producer is not initialized
	case producerNotInitialized
	/// Producer with same name is already connected
	case producerBusy
	/// Too many concurrent lookup requests
	case tooManyLookupRequests
	/// Invalid topic name
	case invalidTopicName
	/// Client initialized with invalid broker URL
	case invalidUrl
	/// Service unit unloaded before producer/consumer creation
	case serviceUnitNotReady
	/// Operation not supported
	case operationNotSupported
	/// Producer is blocked
	case producerBlockedQuotaExceededError
	/// Producer is getting exception
	case producerBlockedQuotaExceededException
	/// Producer queue is full
	case producerQueueIsFull
	/// Trying to send a message exceeding the max size
	case messageTooBig
	/// Topic not found
	case topicNotFound
	/// Subscription not found
	case subscriptionNotFound
	/// Consumer not found
	case consumerNotFound
	/// Older client/version doesn’t support a required feature
	case unsupportedVersionError
	/// Topic was already terminated
	case topicTerminated
	/// Error when crypto operation fails
	case cryptoError

	/// Specified schema is incompatible with the topic's schema
	case incompatibleSchema
	/// Error when assigning messages to a new consumer
	case consumerAssignError
	/// Not allowed to call cumulative acknowledgement in Shared or Key_Shared mode
	case cumulativeAckNotAllowed
	/// Transaction coordinator not found
	case transactionCoordinatorNotFound
	/// Invalid transaction status error
	case invalidTxnStatus
	/// Operation not allowed
	case notAllowed
	/// Transaction acknowledgment conflict
	case transactionConflict
	/// Transaction not found
	case transactionNotFound
	/// Producer was fenced by broker
	case producerFenced

	/// Client-wide memory limit has been reached
	case memoryBufferIsFull
	/// Interrupted while waiting to dequeue
	case interrupted
	/// Client connection has been disconnected
	case disconnected
	/// Schema is not valid
	case invalidSchema

	// MARK: - CustomStringConvertible
	/// A human-readable description of the result.
	public var description: String {
		switch self {
			case .ok: return "OK"
			case .retryable: return "Retryable"
			case .unknownError: return "Unknown Error"
			case .invalidConfiguration: return "Invalid Configuration"
			case .timeout: return "Timeout"
			case .lookupError: return "Lookup Error"
			case .connectError: return "Connect Error"
			case .readError: return "Read Error"
			case .authenticationError: return "Authentication Error"
			case .authorizationError: return "Authorization Error"
			case .errorGettingAuthenticationData: return "Error Getting Authentication Data"
			case .brokerMetadataError: return "Broker Metadata Error"
			case .brokerPersistenceError: return "Broker Persistence Error"
			case .checksumError: return "Checksum Error"
			case .consumerBusy: return "Consumer Busy"
			case .notConnected: return "Not Connected"
			case .alreadyClosed: return "Already Closed"
			case .invalidMessage: return "Invalid Message"
			case .consumerNotInitialized: return "Consumer Not Initialized"
			case .producerNotInitialized: return "Producer Not Initialized"
			case .producerBusy: return "Producer Busy"
			case .tooManyLookupRequests: return "Too Many Lookup Requests"
			case .invalidTopicName: return "Invalid Topic Name"
			case .invalidUrl: return "Invalid URL"
			case .serviceUnitNotReady: return "Service Unit Not Ready"
			case .operationNotSupported: return "Operation Not Supported"
			case .producerBlockedQuotaExceededError: return "Producer Blocked (Quota Exceeded Error)"
			case .producerBlockedQuotaExceededException: return "Producer Blocked (Quota Exceeded Exception)"
			case .producerQueueIsFull: return "Producer Queue Is Full"
			case .messageTooBig: return "Message Too Big"
			case .topicNotFound: return "Topic Not Found"
			case .subscriptionNotFound: return "Subscription Not Found"
			case .consumerNotFound: return "Consumer Not Found"
			case .unsupportedVersionError: return "Unsupported Version Error"
			case .topicTerminated: return "Topic Terminated"
			case .cryptoError: return "Crypto Error"
			case .incompatibleSchema: return "Incompatible Schema"
			case .consumerAssignError: return "Consumer Assign Error"
			case .cumulativeAckNotAllowed: return "Cumulative Acknowledgement Not Allowed"
			case .transactionCoordinatorNotFound: return "Transaction Coordinator Not Found"
			case .invalidTxnStatus: return "Invalid Transaction Status"
			case .notAllowed: return "Not Allowed"
			case .transactionConflict: return "Transaction Conflict"
			case .transactionNotFound: return "Transaction Not Found"
			case .producerFenced: return "Producer Fenced"
			case .memoryBufferIsFull: return "Memory Buffer Is Full"
			case .interrupted: return "Interrupted"
			case .disconnected: return "Disconnected"
			case .invalidSchema: return "Schema is not valid."
		}
	}
}

extension PulsarError {
	init(cxx value: _Pulsar.Result) {
		print(value)
		self = PulsarError(rawValue: Int(value.rawValue)) ?? .unknownError
	}

	var cxxValue: _Pulsar.Result {
		_Pulsar.Result(rawValue: Int8(self.rawValue))
	}
}

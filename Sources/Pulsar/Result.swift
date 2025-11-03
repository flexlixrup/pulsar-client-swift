import Foundation

public enum Result: Int, Error, CustomStringConvertible, Sendable {
	/// An internal error code used for retry
	case retryable = -1
	// Not used just kept for compatibility with C++ enum
	/// Operation completed successfully
	case ok = 0
	case unknownError
	/// Unknown error happened on broker
	case invalidConfiguration
	/// Invalid configuration
	case timeout
	/// Operation timed out
	case lookupError
	/// Broker lookup failed
	case connectError
	/// Failed to connect to broker
	case readError
	/// Failed to read from socket

	case authenticationError
	/// Authentication failed on broker
	case authorizationError
	/// Client not authorized to create producer/consumer
	case errorGettingAuthenticationData
	/// Client cannot find authorization data

	case brokerMetadataError
	/// Broker failed in updating metadata
	case brokerPersistenceError
	/// Broker failed to persist entry
	case checksumError
	/// Corrupt message checksum failure

	case consumerBusy
	/// Exclusive consumer is already connected
	case notConnected
	/// Producer/Consumer is not currently connected to broker
	case alreadyClosed
	/// Producer/Consumer is already closed and not accepting any operation

	case invalidMessage
	/// Error in publishing an already used message

	case consumerNotInitialized
	/// Consumer is not initialized
	case producerNotInitialized
	/// Producer is not initialized
	case producerBusy
	/// Producer with same name is already connected
	case tooManyLookupRequests
	/// Too many concurrent lookup requests

	case invalidTopicName
	/// Invalid topic name
	case invalidUrl
	/// Client initialized with invalid broker URL
	case serviceUnitNotReady
	/// Service unit unloaded before producer/consumer creation
	case operationNotSupported
	/// Operation not supported
	case producerBlockedQuotaExceededError
	/// Producer is blocked
	case producerBlockedQuotaExceededException
	/// Producer is getting exception
	case producerQueueIsFull
	/// Producer queue is full
	case messageTooBig
	/// Trying to send a message exceeding the max size
	case topicNotFound
	/// Topic not found
	case subscriptionNotFound
	/// Subscription not found
	case consumerNotFound
	/// Consumer not found
	case unsupportedVersionError
	/// Older client/version doesn’t support a required feature
	case topicTerminated
	/// Topic was already terminated
	case cryptoError
	/// Error when crypto operation fails

	case incompatibleSchema
	/// Specified schema is incompatible with the topic's schema
	case consumerAssignError
	/// Error when assigning messages to a new consumer
	case cumulativeAckNotAllowed
	/// Not allowed to call cumulative acknowledgement in Shared or Key_Shared mode
	case transactionCoordinatorNotFound
	/// Transaction coordinator not found
	case invalidTxnStatus
	/// Invalid transaction status error
	case notAllowed
	/// Operation not allowed
	case transactionConflict
	/// Transaction acknowledgment conflict
	case transactionNotFound
	/// Transaction not found
	case producerFenced
	/// Producer was fenced by broker

	case memoryBufferIsFull
	/// Client-wide memory limit has been reached
	case interrupted
	/// Interrupted while waiting to dequeue
	case disconnected
	/// Client connection has been disconnected

	// MARK: - CustomStringConvertible
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
		}
	}
}

extension Result {
	init(cxx value: _Pulsar.Result) {
		print(value)
		self = Result(rawValue: Int(value.rawValue)) ?? .unknownError
	}

	var cxxValue: _Pulsar.Result {
		_Pulsar.Result(rawValue: Int32(self.rawValue))
	}
}

enum PulsarError: Error {
	case invalidSchema(String)
	case invalidMessage(String)
	case authenticationError(String)
}

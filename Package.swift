// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "pulsar-client-swift",
	platforms: [.macOS(.v26)],
	products: [
		.library(
			name: "Pulsar",
			targets: ["Pulsar"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
	],
	targets: [
		.target(
			name: "Pulsar",
			dependencies: [
				.target(name: "CxxPulsar"),
				.target(name: "Bridge"),
				.product(name: "Logging", package: "swift-log")
			],
			swiftSettings: [.interoperabilityMode(.Cxx)],
		),
		//.binaryTarget(
		//	name: "CxxPulsar",
		//	url: "https://github.com/flexlixrup/pulsar-client-cpp-bundle/releases/download/v0.1.0/libpulsar.artifactbundle.zip",
		//	checksum: "539b4d7789a9cd63c49d95d2aceb6bda4fc43cbbf14b99a8f61d061933454ed9"
		//),
		.binaryTarget(name: "CxxPulsar", path: "libpulsar.artifactbundle"),
		.target(
			name: "Bridge",
			dependencies: [.target(name: "CxxPulsar")],
			swiftSettings: [.interoperabilityMode(.Cxx)]
		),
		.testTarget(
			name: "PulsarTests",
			dependencies: ["Pulsar"],
			swiftSettings: [.interoperabilityMode(.Cxx)],
		),
		.executableTarget(
			name: "PulsarExample",
			dependencies: [.target(name: "Pulsar")],
			swiftSettings: [.interoperabilityMode(.Cxx)],

		)
	]
)

// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "pulsar-client-swift",
	platforms: [.macOS(.v15)],
	products: [
		.library(
			name: "Pulsar",
			targets: ["Pulsar"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-metrics.git", "1.0.0" ..< "3.0.0")
	],
	targets: [
		.target(
			name: "Pulsar",
			dependencies: [
				.target(name: "CxxPulsar"),
				.target(name: "Bridge"),
				.product(name: "Metrics", package: "swift-metrics"),
				.product(name: "Logging", package: "swift-log")
			],
			resources: [
				.copy("Resources/LICENSES")
			],
			swiftSettings: [.interoperabilityMode(.Cxx)],
		),
		.binaryTarget(
			name: "CxxPulsar",
			url: "https://github.com/flexlixrup/pulsar-client-cpp-bundle/releases/download/v3.8.0/libpulsar.artifactbundle.zip",
			checksum: "57ff09c4c02f7e271cb0762b44cf2ff5c13f3417e4776214391c414c52bd348a"
		),
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

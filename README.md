# pulsar-client-swift

`pulsar-client-swift` is a native Swift wrapper library for the [Apache Pulsar™ C++ client library](https://pulsar.apache.org/docs/4.1.x/client-libraries-cpp/). It provides an idiomatic Swift API (Client, Producer, Consumer, Message, etc.) while calling into the upstream C++ client.

## Quick start

Example (synchronous send):

```swift
import Pulsar

let client = Client(serviceURL: URL(string: "pulsar://localhost:6650")!)
do {
    let producer = try client.createProducer(topic: "my-topic")
    let message = Message(content: "Hello Apache Pulsar")
    try producer.send(message)
    try client.close()
} catch {
    print("Pulsar error: \(error)")
}
```

The full documentation is provided via DocC on [Swift Package Manager](https://swiftpackageindex.com/flexlixrup/pulsar-client-swift-cpp).

## Add to your project

To integrate `pulsar-client-swift` into your project using Swift Package Manager, follow these steps:

1. Open your project in Xcode.
2. Select `File` > `Swift Packages` > `Add Package Dependency...`.
3. Enter the package repository URL: `https://github.com/flexlixrup/pulsar-client-swift-cpp`.
4. Choose the latest release or specify a version range.
5. Add the package to your target.

Alternatively, you can add the following dependency to your `Package.swift` file:

```swift
dependencies: [
	.package(url: "https://github.com/flexlixrup/pulsar-client-swift-cpp", from: "0.0.1")
]
```

Then, include `Pulsar` as a dependency in your target:

```swift
.target(
	name: "YourTargetName",
	dependencies: [
		"Pulsar"
	]),
```

## Licensing

This project includes and links against the [Apache Pulsar™ C++ client library](https://pulsar.apache.org/docs/4.1.x/client-libraries-cpp/). The included C++ client is distributed under the Apache License 2.0. Please review the license files:

- `pulsar-client-swift/LICENSE` — license for the Swift wrapper
- `pulsar-client-cpp-bundle/resources/LICENSES/` — license/NOTICE files for the bundled Apache Pulsar C++ client

## Contributing

> [!WARNING]
> This package uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) to detect the semantic versioning. Commits not following this format will not be accepted.

If you would like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Create a new Pull Request.

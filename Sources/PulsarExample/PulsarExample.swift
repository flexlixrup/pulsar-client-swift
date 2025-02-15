// Copyright 2025 Felix Ruppert
//
// Licensed under the Apache License, Version 2.0 (the License );
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an AS IS BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import Logging
import NIO
import NIOSSL
import Pulsar

@main
struct PulsarExample {
	static func main() async throws {
		let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
		LoggingSystem.bootstrap { label in
			var handler = StreamLogHandler.standardOutput(label: label)
			handler.logLevel = .trace
			return handler
		}
		let connector = PulsarExample()
		try await connector.connect(eventLoopGroup: eventLoopGroup)
	}

	func connect(eventLoopGroup: EventLoopGroup) async throws {
		var msgCount = 0
		var clientCertPath: String? {
			Bundle.module.path(
				forResource: "client-cert",
				ofType: "pem"
			)
		}

		var clientKeyPath: String? {
			Bundle.module.path(forResource: "client-key", ofType: "pem")
		}

		var caCertPath: String? {
			Bundle.module.path(forResource: "ca-cert", ofType: "pem")
		}
		let clientCertificate = try NIOSSLCertificate(file: clientCertPath!, format: .pem)
		let clientPrivateKey = try NIOSSLPrivateKey(file: clientKeyPath!, format: .pem)
		let caCertificate = try NIOSSLCertificate(file: caCertPath!, format: .pem)
		var tlsConfig = TLSConfiguration.makeClientConfiguration()
		tlsConfig.certificateVerification = .fullVerification
		tlsConfig.trustRoots = .certificates([caCertificate])
		tlsConfig.privateKey = .privateKey(clientPrivateKey)
		tlsConfig.certificateChain = [.certificate(clientCertificate)]
		tlsConfig.certificateVerification = .fullVerification
		let auth = TLSConnection(tlsConfiguration: tlsConfig, clientCA: clientCertificate, authenticationRequired: true)

		let config = PulsarClientConfiguration(
			host: "pulsar-dev.internal.com",
			port: 6651,
			tlsConfiguration: auth,
			group: eventLoopGroup,
			reconnectionLimit: 10
		)
		let client = try await PulsarClient(configuration: config) { error in
			print("Error: \(error)")
		}
		let consumer =
			try await client.consumer(
				topic: "persistent://public/default/my-topic2",
				subscription: "test",
				subscriptionType: .shared,
				schema: .string
			) as PulsarConsumer<String>
		Task {
			do {
				for try await message in consumer {
					// Fix an concurrency false-positive in Swift 5.10 - It's only demo code, so no issue
					#if compiler(>=6)
						msgCount += 1
						let stringPayload = message.payload
						print("Received message in the exec: \(stringPayload)")
						if msgCount == 2 {
							try await consumer.close()
							print("Closed consumer")
						}
					#endif
				}
			} catch {
				print("Whooops we closed, this can happen if we e.g delete the topic")
			}
		}

		let producer =
			try await client.producer(topic: "persistent://public/default/my-topic1", accessMode: .shared, schema: .string) { _ in
				print("Produer closed")
			} as PulsarProducer<String>
		Task {
			while true {
				do {
					let testMsg = "Hello from Swift"
					try await producer.asyncSend(message: Message(payload: testMsg))
					try await Task.sleep(for: .seconds(5))
					print("we try to send a message here")
				} catch {
					fatalError("We got a timeout on send")
				}
			}
		}

		let keepAlivePromise = eventLoopGroup.next().makePromise(of: Void.self)
		try await keepAlivePromise.futureResult.get()
	}
}

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

protocol AnyProducer: AnyObject {
	var producerID: UInt64 { get }
	var topic: String { get }
	var stateManager: ProducerStateManager { get }
	var accessMode: ProducerAccessMode { get }
	var schema: PulsarSchema { get }
	var onClosed: (@Sendable (any Error) throws -> Void)? { get }

	func handleClosing() async throws
}

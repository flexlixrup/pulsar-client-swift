#include "ListenerBridge.h"
#include <pulsar/ConsumerConfiguration.h>

// Declare the Swift-provided C symbol so the shim can call it if a callback
// pointer is not provided by the caller.
extern "C" void pulsar_swift_message_listener(void *ctx, void *consumer,
                                              const void *message);

extern "C" void pulsar_consumer_configuration_set_message_listener(
    void *cfg, pulsar_swift_message_listener_t cb, void *ctx) {
  if (!cfg) {
    return;
  }

  auto conf = static_cast<pulsar::ConsumerConfiguration *>(cfg);
  conf->setMessageListener([cb, ctx](pulsar::Consumer &consumer,
                                     const pulsar::Message &msg) {
    // If caller supplied a C function pointer, call it; otherwise call the
    // Swift-provided symbol directly.
    if (cb) {
      cb(ctx, static_cast<void *>(&consumer), static_cast<const void *>(&msg));
    } else {
      pulsar_swift_message_listener(ctx, static_cast<void *>(&consumer),
                                    static_cast<const void *>(&msg));
    }
  });
}

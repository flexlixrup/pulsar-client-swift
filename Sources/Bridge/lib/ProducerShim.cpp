#include "ProducerBridge.h"
#include <pulsar/Producer.h>

// Declare the Swift-provided C symbol so the shim can call it if a callback
// pointer is not provided by the caller.
extern "C" void pulsar_swift_send_callback(void *ctx, int result,
                                           const void *messageId);

extern "C" void pulsar_producer_send_async(void *producer, const void *message,
                                           pulsar_swift_send_callback_t cb,
                                           void *ctx) {
  if (!producer || !message) {
    return;
  }

  auto prod = static_cast<pulsar::Producer *>(producer);
  auto msg = static_cast<const pulsar::Message *>(message);

  prod->sendAsync(
      *msg, [cb, ctx](pulsar::Result res, const pulsar::MessageId &msgId) {
        if (cb) {
          cb(ctx, static_cast<int>(res), static_cast<const void *>(&msgId));
        } else {
          pulsar_swift_send_callback(ctx, static_cast<int>(res),
                                     static_cast<const void *>(&msgId));
        }
      });
}

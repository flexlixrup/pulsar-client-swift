#include "ProducerBridge.h"
#include <pulsar/Producer.h>

extern "C" void pulsar_swift_send_callback(void *ctx, int result,
                                           const void *messageId);

extern "C" void pulsar_producer_send_async(void *producer, const void *message,
                                           void *ctx) {
  if (!producer || !message) {
    return;
  }

  auto prod = static_cast<pulsar::Producer *>(producer);
  auto msg = static_cast<const pulsar::Message *>(message);

  prod->sendAsync(
      *msg, [ctx](pulsar::Result res, const pulsar::MessageId &msgId) {
        pulsar_swift_send_callback(ctx, static_cast<int>(res),
                                   static_cast<const void *>(&msgId));
      });
}

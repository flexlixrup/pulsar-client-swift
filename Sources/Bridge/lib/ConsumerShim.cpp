#include "ConsumerBridge.h"
#include "pulsar/Consumer.h"

extern "C" void pulsar_swift_result_callback(void *ctx, int result);

extern "C" void
pulsar_consumer_acknowledge_async(void *producer, const void *message,
                                  pulsar_swift_result_callback_t cb,
                                  void *ctx) {
  if (!message) {
    return;
  }
  auto cons = static_cast<pulsar::Consumer *>(producer);
  auto msg = static_cast<const pulsar::Message *>(message);

  cons->acknowledgeAsync(*msg, [cb, ctx](pulsar::Result res) {
    if (cb) {
      cb(ctx, static_cast<int>(res));
    } else {
      pulsar_swift_result_callback(ctx, static_cast<int>(res));
    }
  });
}
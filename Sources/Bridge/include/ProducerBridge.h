// ProducerBridge.h
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*pulsar_swift_send_callback_t)(void *ctx, int result,
                                             const void *messageId);

void pulsar_swift_send_callback(void *ctx, int result, const void *messageId);

void pulsar_producer_send_async(void *producer, const void *message,
                                pulsar_swift_send_callback_t cb, void *ctx);

#ifdef __cplusplus
} // extern "C"
#endif

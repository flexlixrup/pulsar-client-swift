// ConsumerBridge.h
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*pulsar_swift_result_callback_t)(void *ctx, int result);

void pulsar_swift_result_callback(void *ctx, int result);

void pulsar_consumer_acknowledge_async(void *consumer, const void *message,
                                       pulsar_swift_result_callback_t cb,
                                       void *ctx);
#ifdef __cplusplus
} // extern "C"
#endif
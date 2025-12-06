// ConsumerBridge.h
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void pulsar_consumer_acknowledge_async(void *consumer, const void *message,
                                       void *ctx);
#ifdef __cplusplus
} // extern "C"
#endif
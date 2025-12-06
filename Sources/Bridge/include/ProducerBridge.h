// ProducerBridge.h
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void pulsar_producer_send_async(void *producer, const void *message, void *ctx);

#ifdef __cplusplus
} // extern "C"
#endif

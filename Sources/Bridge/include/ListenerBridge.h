// ListenerBridge.h
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*pulsar_swift_message_listener_t)(void *ctx, void *consumer,
                                                const void *message);

void pulsar_swift_message_listener(void *ctx, void *consumer,
                                   const void *message);

void pulsar_consumer_configuration_set_message_listener(
    void *cfg, pulsar_swift_message_listener_t cb, void *ctx);

#ifdef __cplusplus
} // extern "C"
#endif

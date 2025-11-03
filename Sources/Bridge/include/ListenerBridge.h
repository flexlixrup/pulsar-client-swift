// ListenerBridge.h
#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// C function pointer type implemented in Swift. The callback receives an
// opaque context pointer (`ctx`), a pointer to the C++ `Consumer` instance
// (`consumer`) and a pointer to the C++ `Message` instance (`message`). The
// message pointer is const because the callback must not modify it.
typedef void (*pulsar_swift_message_listener_t)(void *ctx, void *consumer,
                                                const void *message);

// The Swift implementation provides this C-callable symbol. Declare it here
// so other translation units import it as a C function rather than emit a
// duplicate Swift-defined symbol when referencing it.
void pulsar_swift_message_listener(void *ctx, void *consumer,
                                   const void *message);

/// Set the message listener on a ConsumerConfiguration instance.
/// `cfg` is an opaque pointer to a `pulsar::ConsumerConfiguration` object.
/// `cb` is the C-callable function pointer implemented in Swift.
/// `ctx` is an opaque pointer forwarded to the callback.
void pulsar_consumer_configuration_set_message_listener(
    void *cfg, pulsar_swift_message_listener_t cb, void *ctx);

#ifdef __cplusplus
} // extern "C"
#endif

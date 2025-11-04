// Sources/LoggingBridge/include/LoggingBridge.h
#pragma once
#include <stdint.h>

#ifdef __cplusplus
#include <pulsar/Client.h>

extern "C" {
#endif

typedef void (*PulsarSwiftLogFn)(int32_t level, const char *file, int32_t line,
                                 const char *message);

void pulsar_swift_set_log_callback(PulsarSwiftLogFn fn);

void pulsar_swift_install_logger(pulsar::ClientConfiguration *conf,
                                 int32_t minLevel);

#ifdef __cplusplus
} // extern "C"
#endif

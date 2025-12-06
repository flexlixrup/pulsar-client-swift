#pragma once
#include <pulsar/ClientConfiguration.h>

void Bridge_CC_setMemoryLimit(pulsar::ClientConfiguration *c,
                              unsigned long long v);
void Bridge_CC_setConnectionsPerBroker(pulsar::ClientConfiguration *c, int v);
void Bridge_CC_setOperationTimeoutSeconds(pulsar::ClientConfiguration *c,
                                          int v);
void Bridge_CC_setIOThreads(pulsar::ClientConfiguration *c, int v);
void Bridge_CC_setMessageListenerThreads(pulsar::ClientConfiguration *c, int v);

void Bridge_CC_setConcurrentLookupRequest(pulsar::ClientConfiguration *c,
                                          int v);
void Bridge_CC_setMaxLookupRedirects(pulsar::ClientConfiguration *c, int v);
void Bridge_CC_setInitialBackoffIntervalMs(pulsar::ClientConfiguration *c,
                                           int v);
void Bridge_CC_setMaxBackoffIntervalMs(pulsar::ClientConfiguration *c, int v);

void Bridge_CC_setUseTls(pulsar::ClientConfiguration *c, bool flag);
void Bridge_CC_setTlsPrivateKeyFilePath(pulsar::ClientConfiguration *c,
                                        const char *path);
void Bridge_CC_setTlsCertificateFilePath(pulsar::ClientConfiguration *c,
                                         const char *path);
void Bridge_CC_setTlsTrustCertsFilePath(pulsar::ClientConfiguration *c,
                                        const char *path);
void Bridge_CC_setTlsAllowInsecureConnection(pulsar::ClientConfiguration *c,
                                             bool flag);
void Bridge_CC_setValidateHostName(pulsar::ClientConfiguration *c, bool flag);

void Bridge_CC_setListenerName(pulsar::ClientConfiguration *c,
                               const char *name);

void Bridge_CC_setStatsIntervalInSeconds(pulsar::ClientConfiguration *c,
                                         unsigned int v);
void Bridge_CC_setPartitionsUpdateInterval(pulsar::ClientConfiguration *c,
                                           unsigned int v);
void Bridge_CC_setKeepAliveIntervalInSeconds(pulsar::ClientConfiguration *c,
                                             unsigned int v);

void Bridge_CC_setConnectionTimeout(pulsar::ClientConfiguration *c, int ms);

void Bridge_CC_setProxyServiceUrl(pulsar::ClientConfiguration *c,
                                  const char *url);
void Bridge_CC_setProxyProtocol(pulsar::ClientConfiguration *c,
                                unsigned int raw);

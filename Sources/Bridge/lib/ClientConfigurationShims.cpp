#include "ClientConfigurationBridge.h"
#include <string>

void Bridge_CC_setMemoryLimit(pulsar::ClientConfiguration *c,
                              unsigned long long v) {
  c->setMemoryLimit(v);
}

void Bridge_CC_setConnectionsPerBroker(pulsar::ClientConfiguration *c, int v) {
  c->setConnectionsPerBroker(v);
}

void Bridge_CC_setOperationTimeoutSeconds(pulsar::ClientConfiguration *c,
                                          int v) {
  c->setOperationTimeoutSeconds(v);
}

void Bridge_CC_setIOThreads(pulsar::ClientConfiguration *c, int v) {
  c->setIOThreads(v);
}

void Bridge_CC_setAuthentication(pulsar::ClientConfiguration *c,
                                 pulsar::AuthenticationPtr *auth) {
  if (auth)
    c->setAuth(*auth);
}

void Bridge_CC_setMessageListenerThreads(pulsar::ClientConfiguration *c,
                                         int v) {
  c->setMessageListenerThreads(v);
}

void Bridge_CC_setConcurrentLookupRequest(pulsar::ClientConfiguration *c,
                                          int v) {
  c->setConcurrentLookupRequest(v);
}

void Bridge_CC_setMaxLookupRedirects(pulsar::ClientConfiguration *c, int v) {
  c->setMaxLookupRedirects(v);
}

void Bridge_CC_setInitialBackoffIntervalMs(pulsar::ClientConfiguration *c,
                                           int v) {
  c->setInitialBackoffIntervalMs(v);
}

void Bridge_CC_setMaxBackoffIntervalMs(pulsar::ClientConfiguration *c, int v) {
  c->setMaxBackoffIntervalMs(v);
}

void Bridge_CC_setUseTls(pulsar::ClientConfiguration *c, bool flag) {
  c->setUseTls(flag);
}

void Bridge_CC_setTlsPrivateKeyFilePath(pulsar::ClientConfiguration *c,
                                        const char *path) {
  if (path)
    c->setTlsPrivateKeyFilePath(std::string(path));
}

void Bridge_CC_setTlsCertificateFilePath(pulsar::ClientConfiguration *c,
                                         const char *path) {
  if (path)
    c->setTlsCertificateFilePath(std::string(path));
}

void Bridge_CC_setTlsTrustCertsFilePath(pulsar::ClientConfiguration *c,
                                        const char *path) {
  if (path)
    c->setTlsTrustCertsFilePath(std::string(path));
}

void Bridge_CC_setTlsAllowInsecureConnection(pulsar::ClientConfiguration *c,
                                             bool flag) {
  c->setTlsAllowInsecureConnection(flag);
}

void Bridge_CC_setValidateHostName(pulsar::ClientConfiguration *c, bool flag) {
  c->setValidateHostName(flag);
}

void Bridge_CC_setListenerName(pulsar::ClientConfiguration *c,
                               const char *name) {
  if (name && *name)
    c->setListenerName(std::string(name));
}

void Bridge_CC_setStatsIntervalInSeconds(pulsar::ClientConfiguration *c,
                                         unsigned int v) {
  c->setStatsIntervalInSeconds(v);
}

void Bridge_CC_setPartitionsUpdateInterval(pulsar::ClientConfiguration *c,
                                           unsigned int v) {
  c->setPartititionsUpdateInterval(v);
}

void Bridge_CC_setKeepAliveIntervalInSeconds(pulsar::ClientConfiguration *c,
                                             unsigned int v) {
  c->setKeepAliveIntervalInSeconds(v);
}

void Bridge_CC_setConnectionTimeout(pulsar::ClientConfiguration *c, int ms) {
  c->setConnectionTimeout(ms);
}

void Bridge_CC_setProxyServiceUrl(pulsar::ClientConfiguration *c,
                                  const char *url) {
  if (url)
    c->setProxyServiceUrl(std::string(url));
}

void Bridge_CC_setProxyProtocol(pulsar::ClientConfiguration *c,
                                unsigned int raw) {
  c->setProxyProtocol(pulsar::ClientConfiguration::ProxyProtocol(raw));
}

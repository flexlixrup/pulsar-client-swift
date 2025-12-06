// ConsumerConfigurationShims.cpp
#include "ConsumerConfigurationBridge.h"
#include <pulsar/Client.h>
#include <pulsar/ConsumerConfiguration.h>

void Bridge_ConsumerConfig_setSchema(void *config, const void *schemaInfo) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  auto *si = static_cast<const pulsar::SchemaInfo *>(schemaInfo);
  cc->setSchema(*si);
}

void Bridge_ConsumerConfig_setConsumerType(void *config, int consumerType) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setConsumerType(static_cast<pulsar::ConsumerType>(consumerType));
}

void Bridge_ConsumerConfig_setReceiverQueueSize(void *config, int size) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setReceiverQueueSize(size);
}

void Bridge_ConsumerConfig_setMaxTotalReceiverQueueSizeAcrossPartitions(
    void *config, int maxTotalReceiverQueueSizeAcrossPartitions) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setMaxTotalReceiverQueueSizeAcrossPartitions(
      maxTotalReceiverQueueSizeAcrossPartitions);
}

void Bridge_ConsumerConfig_setConsumerName(void *config,
                                           const char *consumerName) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setConsumerName(std::string(consumerName));
}

void Bridge_ConsumerConfig_setUnAckedMessagesTimeoutMs(
    void *config, unsigned long long milliSeconds) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setUnAckedMessagesTimeoutMs(milliSeconds);
}

void Bridge_ConsumerConfig_setTickDurationInMs(
    void *config, unsigned long long milliSeconds) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setTickDurationInMs(milliSeconds);
}

void Bridge_ConsumerConfig_setNegativeAckRedeliveryDelayMs(
    void *config, long redeliveryDelayMillis) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setNegativeAckRedeliveryDelayMs(redeliveryDelayMillis);
}

void Bridge_ConsumerConfig_setAckGroupingTimeMs(void *config,
                                                long ackGroupingMillis) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setAckGroupingTimeMs(ackGroupingMillis);
}

void Bridge_ConsumerConfig_setAckGroupingMaxSize(void *config,
                                                 long maxGroupingSize) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setAckGroupingMaxSize(maxGroupingSize);
}

void Bridge_ConsumerConfig_setBrokerConsumerStatsCacheTimeInMs(
    void *config, long cacheTimeInMs) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setBrokerConsumerStatsCacheTimeInMs(cacheTimeInMs);
}

void Bridge_ConsumerConfig_setCryptoKeyReader(void *config,
                                              void *cryptoKeyReader) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  auto *reader = static_cast<pulsar::CryptoKeyReaderPtr *>(cryptoKeyReader);
  cc->setCryptoKeyReader(*reader);
}

void Bridge_ConsumerConfig_setCryptoFailureAction(void *config, int action) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setCryptoFailureAction(
      static_cast<pulsar::ConsumerCryptoFailureAction>(action));
}

void Bridge_ConsumerConfig_setReadCompacted(void *config, bool compacted) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setReadCompacted(compacted);
}

void Bridge_ConsumerConfig_setPatternAutoDiscoveryPeriod(void *config,
                                                         int periodInSeconds) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setPatternAutoDiscoveryPeriod(periodInSeconds);
}

void Bridge_ConsumerConfig_setRegexSubscriptionMode(void *config,
                                                    int regexSubscriptionMode) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setRegexSubscriptionMode(
      static_cast<pulsar::RegexSubscriptionMode>(regexSubscriptionMode));
}

void Bridge_ConsumerConfig_setSubscriptionInitialPosition(
    void *config, int subscriptionInitialPosition) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setSubscriptionInitialPosition(
      static_cast<pulsar::InitialPosition>(subscriptionInitialPosition));
}

void Bridge_ConsumerConfig_setReplicateSubscriptionStateEnabled(void *config,
                                                                bool enabled) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setReplicateSubscriptionStateEnabled(enabled);
}

void Bridge_ConsumerConfig_setProperty(void *config, const char *name,
                                       const char *value) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setProperty(std::string(name), std::string(value));
}

void Bridge_ConsumerConfig_setSubscriptionProperties(void *config,
                                                     const void *properties) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  auto *props =
      static_cast<const std::map<std::string, std::string> *>(properties);
  cc->setSubscriptionProperties(*props);
}

void Bridge_ConsumerConfig_setPriorityLevel(void *config, int priorityLevel) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setPriorityLevel(priorityLevel);
}

void Bridge_ConsumerConfig_setMaxPendingChunkedMessage(
    void *config, unsigned long maxPendingChunkedMessage) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setMaxPendingChunkedMessage(maxPendingChunkedMessage);
}

void Bridge_ConsumerConfig_setAutoAckOldestChunkedMessageOnQueueFull(
    void *config, bool autoAck) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setAutoAckOldestChunkedMessageOnQueueFull(autoAck);
}

void Bridge_ConsumerConfig_setExpireTimeOfIncompleteChunkedMessageMs(
    void *config, long expireTimeMs) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setExpireTimeOfIncompleteChunkedMessageMs(expireTimeMs);
}

void Bridge_ConsumerConfig_setStartMessageIdInclusive(
    void *config, bool startMessageIdInclusive) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setStartMessageIdInclusive(startMessageIdInclusive);
}

void Bridge_ConsumerConfig_setBatchIndexAckEnabled(void *config, bool enabled) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setBatchIndexAckEnabled(enabled);
}

void Bridge_ConsumerConfig_setAckReceiptEnabled(void *config,
                                                bool ackReceiptEnabled) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setAckReceiptEnabled(ackReceiptEnabled);
}

void Bridge_ConsumerConfig_setStartPaused(void *config, bool startPaused) {
  auto *cc = static_cast<pulsar::ConsumerConfiguration *>(config);
  cc->setStartPaused(startPaused);
}

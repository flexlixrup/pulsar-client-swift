// ConsumerConfigurationBridge.h
#pragma once

void Bridge_ConsumerConfig_setSchema(void *config, const void *schemaInfo);
void Bridge_ConsumerConfig_setConsumerType(void *config, int consumerType);
void Bridge_ConsumerConfig_setReceiverQueueSize(void *config, int size);
void Bridge_ConsumerConfig_setMaxTotalReceiverQueueSizeAcrossPartitions(
    void *config, int maxTotalReceiverQueueSizeAcrossPartitions);
void Bridge_ConsumerConfig_setConsumerName(void *config,
                                           const char *consumerName);
void Bridge_ConsumerConfig_setUnAckedMessagesTimeoutMs(
    void *config, unsigned long long milliSeconds);
void Bridge_ConsumerConfig_setTickDurationInMs(void *config,
                                               unsigned long long milliSeconds);
void Bridge_ConsumerConfig_setNegativeAckRedeliveryDelayMs(
    void *config, long redeliveryDelayMillis);
void Bridge_ConsumerConfig_setAckGroupingTimeMs(void *config,
                                                long ackGroupingMillis);
void Bridge_ConsumerConfig_setAckGroupingMaxSize(void *config,
                                                 long maxGroupingSize);
void Bridge_ConsumerConfig_setBrokerConsumerStatsCacheTimeInMs(
    void *config, long cacheTimeInMs);
void Bridge_ConsumerConfig_setCryptoKeyReader(void *config,
                                              void *cryptoKeyReader);
void Bridge_ConsumerConfig_setCryptoFailureAction(void *config, int action);
void Bridge_ConsumerConfig_setReadCompacted(void *config, bool compacted);
void Bridge_ConsumerConfig_setPatternAutoDiscoveryPeriod(void *config,
                                                         int periodInSeconds);
void Bridge_ConsumerConfig_setRegexSubscriptionMode(void *config,
                                                    int regexSubscriptionMode);
void Bridge_ConsumerConfig_setSubscriptionInitialPosition(
    void *config, int subscriptionInitialPosition);
void Bridge_ConsumerConfig_setReplicateSubscriptionStateEnabled(void *config,
                                                                bool enabled);
void Bridge_ConsumerConfig_setProperty(void *config, const char *name,
                                       const char *value);
void Bridge_ConsumerConfig_setSubscriptionProperties(void *config,
                                                     const void *properties);
void Bridge_ConsumerConfig_setPriorityLevel(void *config, int priorityLevel);
void Bridge_ConsumerConfig_setMaxPendingChunkedMessage(
    void *config, unsigned long maxPendingChunkedMessage);
void Bridge_ConsumerConfig_setAutoAckOldestChunkedMessageOnQueueFull(
    void *config, bool autoAck);
void Bridge_ConsumerConfig_setExpireTimeOfIncompleteChunkedMessageMs(
    void *config, long expireTimeMs);
void Bridge_ConsumerConfig_setStartMessageIdInclusive(
    void *config, bool startMessageIdInclusive);
void Bridge_ConsumerConfig_setBatchIndexAckEnabled(void *config, bool enabled);
void Bridge_ConsumerConfig_setAckReceiptEnabled(void *config,
                                                bool ackReceiptEnabled);
void Bridge_ConsumerConfig_setStartPaused(void *config, bool startPaused);

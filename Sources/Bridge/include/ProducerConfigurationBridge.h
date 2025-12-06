// ProducerConfigurationBridge.h
#pragma once

void Bridge_PC_setProducerName(void *config, const char *producerName);
void Bridge_PC_setSchema(void *config, const void *schemaInfo);
void Bridge_PC_setSendTimeout(void *config, int sendTimeoutMs);
void Bridge_PC_setInitialSequenceId(void *config, long long initialSequenceId);
void Bridge_PC_setCompressionType(void *config, int compressionType);
void Bridge_PC_setMaxPendingMessages(void *config, int maxPendingMessages);
void Bridge_PC_setMaxPendingMessagesAcrossPartitions(
    void *config, int maxPendingMessagesAcrossPartitions);
void Bridge_PC_setPartitionsRoutingMode(void *config, int mode);
void Bridge_PC_setHashingScheme(void *config, int scheme);
void Bridge_PC_setLazyStartPartitionedProducers(void *config, bool lazy);
void Bridge_PC_setBlockIfQueueFull(void *config, bool block);
void Bridge_PC_setBatchingEnabled(void *config, bool enabled);
void Bridge_PC_setBatchingMaxMessages(void *config, unsigned int maxMessages);
void Bridge_PC_setBatchingMaxAllowedSizeInBytes(void *config,
                                                unsigned long maxSizeInBytes);
void Bridge_PC_setBatchingMaxPublishDelayMs(void *config,
                                            unsigned long delayMs);
void Bridge_PC_setBatchingType(void *config, int batchingType);
void Bridge_PC_setChunkingEnabled(void *config, bool enabled);
void Bridge_PC_setAccessMode(void *config, int accessMode);
void Bridge_PC_setProperty(void *config, const char *name, const char *value);

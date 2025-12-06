// ProducerConfigurationShims.cpp
#include "ProducerConfigurationBridge.h"
#include <pulsar/Client.h>
#include <pulsar/ProducerConfiguration.h>

void Bridge_PC_setProducerName(void *config, const char *producerName) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setProducerName(std::string(producerName));
}

void Bridge_PC_setSchema(void *config, const void *schemaInfo) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  auto *si = static_cast<const pulsar::SchemaInfo *>(schemaInfo);
  pc->setSchema(*si);
}

void Bridge_PC_setSendTimeout(void *config, int sendTimeoutMs) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setSendTimeout(sendTimeoutMs);
}

void Bridge_PC_setInitialSequenceId(void *config, long long initialSequenceId) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setInitialSequenceId(initialSequenceId);
}

void Bridge_PC_setCompressionType(void *config, int compressionType) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setCompressionType(static_cast<pulsar::CompressionType>(compressionType));
}

void Bridge_PC_setMaxPendingMessages(void *config, int maxPendingMessages) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setMaxPendingMessages(maxPendingMessages);
}

void Bridge_PC_setMaxPendingMessagesAcrossPartitions(
    void *config, int maxPendingMessagesAcrossPartitions) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setMaxPendingMessagesAcrossPartitions(maxPendingMessagesAcrossPartitions);
}

void Bridge_PC_setPartitionsRoutingMode(void *config, int mode) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setPartitionsRoutingMode(
      static_cast<pulsar::ProducerConfiguration::PartitionsRoutingMode>(mode));
}

void Bridge_PC_setHashingScheme(void *config, int scheme) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setHashingScheme(
      static_cast<pulsar::ProducerConfiguration::HashingScheme>(scheme));
}

void Bridge_PC_setLazyStartPartitionedProducers(void *config, bool lazy) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setLazyStartPartitionedProducers(lazy);
}

void Bridge_PC_setBlockIfQueueFull(void *config, bool block) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setBlockIfQueueFull(block);
}

void Bridge_PC_setBatchingEnabled(void *config, bool enabled) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setBatchingEnabled(enabled);
}

void Bridge_PC_setBatchingMaxMessages(void *config, unsigned int maxMessages) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setBatchingMaxMessages(maxMessages);
}

void Bridge_PC_setBatchingMaxAllowedSizeInBytes(void *config,
                                                unsigned long maxSizeInBytes) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setBatchingMaxAllowedSizeInBytes(maxSizeInBytes);
}

void Bridge_PC_setBatchingMaxPublishDelayMs(void *config,
                                            unsigned long delayMs) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setBatchingMaxPublishDelayMs(delayMs);
}

void Bridge_PC_setBatchingType(void *config, int batchingType) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setBatchingType(
      static_cast<pulsar::ProducerConfiguration::BatchingType>(batchingType));
}

void Bridge_PC_setChunkingEnabled(void *config, bool enabled) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setChunkingEnabled(enabled);
}

void Bridge_PC_setAccessMode(void *config, int accessMode) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setAccessMode(
      static_cast<pulsar::ProducerConfiguration::ProducerAccessMode>(
          accessMode));
}

void Bridge_PC_setProperty(void *config, const char *name, const char *value) {
  auto *pc = static_cast<pulsar::ProducerConfiguration *>(config);
  pc->setProperty(std::string(name), std::string(value));
}
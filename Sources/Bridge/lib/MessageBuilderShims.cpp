#include "MessageBuilderBridge.h"
#include <string>

void Bridge_MB_setContent(pulsar::MessageBuilder *b, const void *data,
                          size_t size) {
  b->setContent(data, size);
}

void Bridge_MB_setProperty(pulsar::MessageBuilder *b, const char *name,
                           const char *value) {
  b->setProperty(name ? std::string{name} : std::string{},
                 value ? std::string{value} : std::string{});
}

void Bridge_MB_setAllocatedContent(pulsar::MessageBuilder *b, void *data,
                                   size_t size) {
  b->setAllocatedContent(data, size);
}

void Bridge_MB_disableReplication(pulsar::MessageBuilder *b, bool flag) {
  b->disableReplication(flag);
}

void Bridge_MB_setDeliverAt(pulsar::MessageBuilder *b, unsigned long long ts) {
  b->setDeliverAt(ts);
}

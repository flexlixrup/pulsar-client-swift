#pragma once
#include <pulsar/MessageBuilder.h>
#include <stddef.h>

void Bridge_MB_setContent(pulsar::MessageBuilder *b, const void *data,
                          size_t size);

void Bridge_MB_setProperty(pulsar::MessageBuilder *b, const char *name,
                           const char *value);

void Bridge_MB_setAllocatedContent(pulsar::MessageBuilder *b, void *data,
                                   size_t size);

void Bridge_MB_disableReplication(pulsar::MessageBuilder *b, bool flag);
void Bridge_MB_setDeliverAt(pulsar::MessageBuilder *b, unsigned long long ts);
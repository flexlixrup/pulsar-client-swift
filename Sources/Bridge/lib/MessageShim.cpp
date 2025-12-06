#include "MessageBridge.h"
#include <cstdlib>
#include <cstring>
#include <pulsar/Message.h>

size_t getDataFromMessage(const void *message, void **outData) {
  if (!message || !outData) {
    *outData = nullptr;
    return 0;
  }

  auto msg = static_cast<const pulsar::Message *>(message);
  const void *data = msg->getData();
  size_t size = msg->getLength();

  if (size == 0) {
    *outData = nullptr;
    return 0;
  }

  void *buffer = malloc(size);
  if (!buffer) {
    *outData = nullptr;
    return 0;
  }

  memcpy(buffer, data, size);
  *outData = buffer;
  return size;
}

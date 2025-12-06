// MessageBridge.h
#pragma once

#include <stddef.h>

// Get message data as a newly allocated buffer that Swift owns
// Returns the size of the data, and fills outData with a malloc'd pointer
// Caller is responsible for freeing the returned pointer
size_t getDataFromMessage(const void *message, void **outData);

#include "PulsarSwiftBridge.h"
#include <atomic>
#include <string>

using pulsar::ClientConfiguration;
using pulsar::Logger;
using pulsar::LoggerFactory;

static std::atomic<PulsarSwiftLogFn> gSwiftLogFn{nullptr};

extern "C" void pulsar_swift_set_log_callback(PulsarSwiftLogFn fn) {
  gSwiftLogFn.store(fn, std::memory_order_release);
}

namespace {
class SwiftLogger : public Logger {
public:
  SwiftLogger(Level minLevel, std::string fileName)
      : minLevel_(minLevel), fileName_(std::move(fileName)) {}

  bool isEnabled(Level level) override { return level >= minLevel_; }

  void log(Level level, int line, const std::string &message) override {
    if (auto fn = gSwiftLogFn.load(std::memory_order_acquire)) {
      fn(static_cast<int32_t>(level), fileName_.c_str(), line, message.c_str());
    }
  }

private:
  Level minLevel_;
  std::string fileName_;
};

class SwiftLoggerFactory : public LoggerFactory {
public:
  explicit SwiftLoggerFactory(Logger::Level minLevel) : minLevel_(minLevel) {}
  Logger *getLogger(const std::string &fileName) override {
    return new SwiftLogger(minLevel_, fileName);
  }

private:
  Logger::Level minLevel_;
};
} // namespace

extern "C" void pulsar_swift_install_logger(ClientConfiguration *conf,
                                            int32_t minLevelInt) {
  Logger::Level lvl = Logger::Level::LEVEL_ERROR;
  switch (minLevelInt) {
  case 0:
    lvl = Logger::Level::LEVEL_DEBUG;
    break;
  case 1:
    lvl = Logger::Level::LEVEL_INFO;
    break;
  case 2:
    lvl = Logger::Level::LEVEL_WARN;
    break;
  case 3:
  default:
    lvl = Logger::Level::LEVEL_ERROR;
    break;
  }
  conf->setLogger(new SwiftLoggerFactory(lvl));
}

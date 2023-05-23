#ifndef CALLBACK_STREAM_H
#define CALLBACK_STREAM_H

#include <streambuf>
#include <mutex>

typedef void (*STREAM_CALLBACK)(const char* data, size_t size);

struct callback_ostreambuf : public std::streambuf {
  callback_ostreambuf(STREAM_CALLBACK callback) : callback(callback) {}

 protected:
  std::streamsize xsputn(const char_type* s, std::streamsize n) override {
    std::lock_guard<std::mutex> lock(callback_mutex);
    callback(s, n);
    return n;
  };

  int_type overflow(int_type ch) override {
    std::lock_guard<std::mutex> lock(callback_mutex);
    if (ch != traits_type::eof()) {
      char c = ch;
      callback(&c, 1);
    }
    return ch;
  }

 private:
  STREAM_CALLBACK callback;
  std::mutex callback_mutex;
};

#endif

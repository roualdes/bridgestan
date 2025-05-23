#ifndef BRIDGESTAN_UTIL_HPP
#define BRIDGESTAN_UTIL_HPP

#include <string>
#include <vector>
#include <cstring>
#include <sstream>

namespace bridgestan {

/**
 * Convert the specified sequence of names to comma-separated value
 * format.  This does a heap allocation, so the resulting string
 * must be freed to prevent a memory leak.  The CSV is output
 * without additional space around the commas.
 *
 * @param names sequence of names to convert
 * @return CSV formatted sequence of names
 */
inline char* to_csv(const std::vector<std::string>& names) {
  std::stringstream ss;
  for (size_t i = 0; i < names.size(); ++i) {
    if (i > 0)
      ss << ',';
    ss << names[i];
  }
  std::string s = ss.str();
  const char* s_c = s.c_str();
  return strdup(s_c);
}

/**
 * Convert exception-style error handling into our C output parameter
 * style. F is always a lambda, so this code gets inlined and the function
 * call overhead is optimized away.
 */
template <typename F>
[[gnu::always_inline]] [[msvc::forceinline]]
inline auto handle_errors(const char* name, char** error_msg, F f) {
  try {
    return f();
  } catch (const std::exception& e) {
    if (error_msg) {
      std::stringstream error;
      error << name << "() failed with exception: " << e.what() << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  } catch (...) {
    if (error_msg) {
      std::stringstream error;
      error << name << "() failed with unknown exception" << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }

  // Handle the return value in the failure case, generically
  using Result = std::invoke_result_t<F>;
  if constexpr (std::is_same_v<Result, int>) {
    return -1;
  } else if constexpr (std::is_pointer_v<Result>) {
    return static_cast<Result>(nullptr);
  } else {
    // if you end up here as a developer, you need to add a
    // new case for the return type of your function
    static_assert(std::is_same_v<Result, void>, "Unexpected return type");
  }
}

}  // namespace bridgestan
#endif

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

}  // namespace bridgestan
#endif

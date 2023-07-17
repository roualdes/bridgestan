#ifndef BRIDGESTAN_VERSION_HPP
#define BRIDGESTAN_VERSION_HPP

#include <string>

#ifndef BRIDGESTAN_STRING_EXPAND
#define BRIDGESTAN_STRING_EXPAND(s) #s
#endif

#ifndef BRIDGESTAN_STRING
#define BRIDGESTAN_STRING(s) BRIDGESTAN_STRING_EXPAND(s)
#endif

#define BRIDGESTAN_MAJOR 2
#define BRIDGESTAN_MINOR 1
#define BRIDGESTAN_PATCH 1

namespace bridgestan {

/** Major version number for BridgeStan. */
const std::string MAJOR_VERSION = BRIDGESTAN_STRING(BRIDGESTAN_MAJOR);

/** Minor version number for BridgeStan. */
const std::string MINOR_VERSION = BRIDGESTAN_STRING(BRIDGESTAN_MINOR);

/** Patch version for BridgeStan. */
const std::string PATCH_VERSION = BRIDGESTAN_STRING(BRIDGESTAN_PATCH);

}  // namespace bridgestan

#endif

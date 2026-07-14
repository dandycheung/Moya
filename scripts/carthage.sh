#!/usr/bin/env bash

# carthage.sh
# Usage example: ./carthage.sh build --platform iOS

set -euo pipefail

xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)
trap 'rm -f "$xcconfig"' INT TERM HUP EXIT

# Exclude arm64 from all simulator builds to prevent lipo conflicts.
# On Apple Silicon, both device and simulator build for arm64 by default,
# which makes lipo fail when creating fat frameworks.
echo 'EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64' >> $xcconfig
echo 'EXCLUDED_ARCHS[sdk=watchsimulator*] = arm64' >> $xcconfig
echo 'EXCLUDED_ARCHS[sdk=appletvsimulator*] = arm64' >> $xcconfig
echo 'EXCLUDED_ARCHS[sdk=xrsimulator*] = arm64' >> $xcconfig

# Suppress strict-prototypes warning in Xcode 16+.
echo 'GCC_WARN_STRICT_PROTOTYPES = NO' >> $xcconfig
echo 'OTHER_CFLAGS = $(inherited) -Wno-error=strict-prototypes' >> $xcconfig

# Xcode 16 removed libarclite for very old deployment targets (e.g. iOS 8, macOS 10.9).
# Use SDK-conditional syntax so each setting only applies when building for that SDK.
# Without this, IPHONEOS_DEPLOYMENT_TARGET set globally on Apple Silicon causes macOS
# builds to be treated as "Designed for iPad on Mac" (arm64-apple-ios instead of
# arm64-apple-macos), breaking framework module lookups.
echo 'IPHONEOS_DEPLOYMENT_TARGET[sdk=iphoneos*] = 12.0' >> $xcconfig
echo 'IPHONEOS_DEPLOYMENT_TARGET[sdk=iphonesimulator*] = 12.0' >> $xcconfig
echo 'TVOS_DEPLOYMENT_TARGET[sdk=appletvos*] = 12.0' >> $xcconfig
echo 'TVOS_DEPLOYMENT_TARGET[sdk=appletvsimulator*] = 12.0' >> $xcconfig
echo 'WATCHOS_DEPLOYMENT_TARGET[sdk=watchos*] = 5.0' >> $xcconfig
echo 'WATCHOS_DEPLOYMENT_TARGET[sdk=watchsimulator*] = 5.0' >> $xcconfig
echo 'MACOSX_DEPLOYMENT_TARGET[sdk=macosx*] = 10.15' >> $xcconfig

export XCODE_XCCONFIG_FILE="$xcconfig"
carthage "$@"

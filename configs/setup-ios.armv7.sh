#!/bin/bash

ARCH="armv7"
PLATFORM_DEFINITION="defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && defined(__ARM_ARCH_7A__)"

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
SDK_VERSION_NAME="iphoneos"

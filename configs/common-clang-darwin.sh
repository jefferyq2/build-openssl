#!/bin/bash

SDK_FLAG="${SDK_VERSION_NAME}-version-min=${MIN_OS_VERSION}"

export CC="${CLANG_PATH} -m${SDK_FLAG} -isysroot ${SDK_PATH} -fembed-bitcode ${COMP_FLAGS}"
export LDFLAGS="-m${SDK_FLAG} -isysroot ${SDK_PATH}"

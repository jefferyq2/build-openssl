#!/bin/bash

PFIX="${ANDROID_NDK_HOME}/toolchains/${GCC_ARCH}-${ANDROID_GCC_VERSION}/prebuilt/darwin-x86_64/bin/${GCC_PREFIX}"

export SYSROOT="${ANDROID_NDK_HOME}/sysroot"
export PLATROOT="${ANDROID_NDK_HOME}/platforms/android-${ANDROID_PLATFORM}/arch-${PLATFORM_ARCH}"
export SYSINC="${SYSROOT}/usr/include/${GCC_PREFIX}"
export CC="${PFIX}-gcc"
export RANLIB="${PFIX}-ranlib"
export AR="${PFIX}-ar"
export AS="${PFIX}-as"
export CPP="${PFIX}-cpp"
export CXX="${PFIX}-g++"
export LD="${PFIX}-ld"
export STRIP="${PFIX}-strip"
export CFLAGS="--sysroot=${SYSROOT} -isystem \"${SYSINC}\" -D__ANDROID_API__=${ANDROID_PLATFORM} ${COMP_FLAGS}"
export LDFLAGS="--sysroot=${PLATROOT}"

ANDROID_BUILD_PIE="${ANDROID_BUILD_PIE:-true}"
if [ "${ANDROID_BUILD_PIE}" == "true" ]; then
    export CFLAGS="${CFLAGS} -fPIE"
    export LDFLAGS="${LDFLAGS} -fPIE -pie"
fi

export CC="${CC} ${CFLAGS}"

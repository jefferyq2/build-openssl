#!/bin/bash

cd "$(dirname "${0}")"
BUILD_DIR="$(pwd)"
cd ->/dev/null

# Homebrew bootstrapping information
: ${HB_BOOTSTRAP_GIST_URL:="https://gist.githubusercontent.com/toonetown/48101686e509fda81335/raw"}
HB_BOOTSTRAP="b:autoconf b:automake b:libtool b:dos2unix
              t:toonetown/extras b:toonetown-extras s:toonetown-extras"

# Overridable build locations
: ${DEFAULT_OPENSSL_DIST:="${BUILD_DIR}/openssl"}
: ${OBJDIR_ROOT:="${BUILD_DIR}/target"}
: ${CONFIGS_DIR:="${BUILD_DIR}/configs"}
: ${MAKE_BUILD_PARALLEL:=$(sysctl -n hw.ncpu)}

# Packages to bundle - macosx last, so we get the right line endings
: ${PKG_COMBINED_PLATS:="windows.x86_64 macosx"}

# Options for OpenSSL - default ones are very secure (most stuff disabled)
: ${COMMON_OPENSSL_BUILD_OPTIONS:="no-shared"}
: ${OPENSSL_BUILD_OPTIONS:="no-afalgeng         \
                            no-aria             \
                            no-blake2           \
                            no-camellia         \
                            no-capieng          \
                            no-cast             \
                            no-chacha           \
                            no-cmac             \
                            no-cms              \
                            no-ct               \
                            no-deprecated       \
                            no-des              \
                            no-dtls             \
                            no-dtls1-method     \
                            no-dtls1_2-method   \
                            no-engine           \
                            no-filenames        \
                            no-gost             \
                            no-heartbeats       \
                            no-hw-padlock       \
                            no-idea             \
                            no-md2              \
                            no-md4              \
                            no-mdc2             \
                            no-nextprotoneg     \
                            no-ocb              \
                            no-poly1305         \
                            no-rc2              \
                            no-rc4              \
                            no-rc5              \
                            no-rdrand           \
                            no-rfc3779          \
                            no-rmd160           \
                            no-scrypt           \
                            no-sctp             \
                            no-seed             \
                            no-siphash          \
                            no-sm2              \
                            no-sm3              \
                            no-sm4              \
                            no-srp              \
                            no-srtp             \
                            no-ssl              \
                            no-ssl3-method      \
                            no-static-engine    \
                            no-tests            \
                            no-whirlpool        \
                            no-zlib"}

# Include files which are platform-specific
PLATFORM_SPECIFIC_HEADERS="openssl/opensslconf.h"

list_arch() {
    if [ -z "${1}" ]; then
        PFIX="${CONFIGS_DIR}/setup-*"
    else
        PFIX="${CONFIGS_DIR}/setup-${1}"
    fi
    ls -m ${PFIX}.*.sh 2>/dev/null | sed "s#${CONFIGS_DIR}/setup-\(.*\)\.sh#\1#" | \
                         tr -d '\n' | \
                         sed -e 's/ \+/ /g' | sed -e 's/^ *\(.*\) *$/\1/g'
}

list_plats() {
    for i in $(list_arch | sed -e 's/,//g'); do
        echo "${i}" | cut -d'.' -f1
    done | sort -u
}

print_usage() {
    while [ $# -gt 0 ]; do
        echo "${1}" >&2
        shift 1
        if [ $# -eq 0 ]; then echo "" >&2; fi
    done
    echo "Usage: ${0} [/path/to/openssl-dist] <plat.arch|plat|'bootstrap'|'clean'>"         >&2
    echo ""                                                                                 >&2
    echo "\"/path/to/openssl-dist\" is optional and defaults to:"                           >&2
    echo "    \"${DEFAULT_OPENSSL_DIST}\""                                                  >&2
    echo ""                                                                                 >&2
    echo "Possible plat.arch combinations are:"                                             >&2
    for p in $(list_plats); do
        echo "    ${p}:"                                                                    >&2
        echo "        $(list_arch ${p})"                                                    >&2
        echo ""                                                                             >&2
    done
    echo "If you specify just a plat, then *all* architectures will be built for that"      >&2
    echo "platform, and the resulting libraries will be \"lipo\"-ed together to a single"   >&2
    echo "fat binary (if supported)."                                                       >&2
    echo ""                                                                                 >&2
    echo "When specifying clean, you may optionally include a plat or plat.arch to clean,"  >&2
    echo "i.e. \"${0} clean macosx.i386\" to clean only the i386 architecture on Mac OS X"  >&2
    echo "or \"${0} clean ios\" to clean all ios builds."                                   >&2
    echo ""                                                                                 >&2
    echo "You can copy the windows outputs to non-windows target directory by running"      >&2
    echo "\"${0} copy-windows /path/to/windows/target"                                      >&2
    echo ""                                                                                 >&2
    echo "You can specify to package the release (after it's already been built) by"        >&2
    echo "running \"${0} package /path/to/output"                                           >&2
    echo ""                                                                                 >&2
    return 1
}

do_bootstrap() {
    curl -sSL "${HB_BOOTSTRAP_GIST_URL}" | /bin/bash -s -- ${HB_BOOTSTRAP}
}

do_build_openssl() {
    TARGET="${1}"
    OUTPUT_ROOT="${2}"
    BUILD_ROOT="${OUTPUT_ROOT}/build/openssl"

    [ -n "${PLATFORM_DEFINITION}" ] || {
        echo "PLATFORM_DEFINITION is not set for ${TARGET}"
        return 1
    }
    [ -n "${OPENSSL_CONFIGURE_NAME}" ] || {
        echo "OPENSSL_CONFIGURE_NAME is not set for ${TARGET}"
        return 1
    }

    [ -d "${BUILD_ROOT}" ] || {
        echo "Creating build directory for '${TARGET}'..."
        mkdir -p "${BUILD_ROOT}" || return $?
    }
    
    if [ ! -f "${BUILD_ROOT}/Makefile" ]; then
        echo "Configuring OpenSSL build directory for '${TARGET}'..."
        cd "${BUILD_ROOT}" || return $?
        [ -n "${OPENSSL_PRECONFIGURE}" ] && {
            [ -x "${OPENSSL_PRECONFIGURE}" ] || { echo "${OPENSSL_PRECONFIGURE} does not exist"; return 1; }
            source "${OPENSSL_PRECONFIGURE}" || return $?
        }
        "${PATH_TO_OPENSSL_DIST}/Configure" ${OPENSSL_CONFIGURE_NAME} \
                                            ${COMMON_OPENSSL_BUILD_OPTIONS} \
                                            ${OPENSSL_BUILD_OPTIONS} \
                                            --prefix="${OUTPUT_ROOT}" \
                                            --openssldir="${OUTPUT_ROOT}" || {
            rm -f "${BUILD_ROOT}/Makefile"
            return 1
        }
        cd ->/dev/null
    fi

    cd "${BUILD_ROOT}"
    echo "Building OpenSSL architecture '${TARGET}'..."
    
    # Generate the project and build (and clean up cruft directories)
    make -j ${MAKE_BUILD_PARALLEL} && make install_sw
    ret=$?
    rm -rf "${OUTPUT_ROOT}"/{bin,certs,misc,private,lib/engines*,lib/pkgconfig,openssl.cnf} >/dev/null 2>&1
    
    # Update platform-specific headers
    if [ ${ret} -eq 0 ]; then
        _INC_OUT="${OUTPUT_ROOT}/include"
        for h in ${PLATFORM_SPECIFIC_HEADERS}; do
            echo "Updating header '${h}' for ${TARGET}..."
            echo "#if ${PLATFORM_DEFINITION}" > "${_INC_OUT}/${h}.tmp"
            cat "${_INC_OUT}/${h}" >> "${_INC_OUT}/${h}.tmp"
            echo "#endif" >> "${_INC_OUT}/${h}.tmp"
            mv "${_INC_OUT}/${h}.tmp" "${_INC_OUT}/${h}" || { ret=$?; break; }
        done
    fi

    cd ->/dev/null
    return ${ret}
}

do_build() {
    TARGET="${1}"; shift
    PLAT="$(echo "${TARGET}" | cut -d'.' -f1)"
    ARCH="$(echo "${TARGET}" | cut -d'.' -f2)"
    CONFIG_SETUP="${CONFIGS_DIR}/setup-${TARGET}.sh"
    
    # Clean here - in case we pass a "clean" command
    if [ "${1}" == "clean" ]; then do_clean ${TARGET}; return $?; fi

    if [ -f "${CONFIG_SETUP}" -a "${PLAT}" != "${ARCH}" ]; then
        # Load configuration files
        [ -f "${CONFIGS_DIR}/setup-${PLAT}.sh" ] && {
            source "${CONFIGS_DIR}/setup-${PLAT}.sh"    || return $?
        }
        source "${CONFIG_SETUP}" && source "${GEN_SCRIPT}" || return $?
        do_build_openssl ${TARGET} "${OBJDIR_ROOT}/objdir-${TARGET}" || return $?
        
        return $?
    elif [ -n "${TARGET}" -a -n "$(list_arch ${TARGET})" ]; then
        PLATFORM="${TARGET}"

        # Load configuration file for the platform
        [ -f "${CONFIGS_DIR}/setup-${PLATFORM}.sh" ] && {
            source "${CONFIGS_DIR}/setup-${PLATFORM}.sh"    || return $?
        }
        
        if [ -n "${LIPO_PATH}" ]; then
            echo "Building fat binary for platform '${PLATFORM}'..."
        else
            echo "Building all architectures for platform '${PLATFORM}'..."
        fi

        COMBINED_ARCHS="$(list_arch ${PLATFORM} | sed -e 's/,//g')"
        for a in ${COMBINED_ARCHS}; do
            do_build ${a} || return $?
        done
        
        # Combine platform-specific headers
        COMBINED_ROOT="${OBJDIR_ROOT}/objdir-${PLATFORM}"
        mkdir -p "${COMBINED_ROOT}" || return $?
        cp -r ${COMBINED_ROOT}.*/include ${COMBINED_ROOT} || return $?
        _CMB_INC="${COMBINED_ROOT}/include"
        
        for h in ${PLATFORM_SPECIFIC_HEADERS}; do
            echo "Combining header '${h}'..."
            if [ -f "${_CMB_INC}/${h}" ]; then
                rm ${_CMB_INC}/${h} || return $?
                for a in ${COMBINED_ARCHS}; do
                    _A_INC="${OBJDIR_ROOT}/objdir-${a}/include"
                    cat "${_A_INC}/${h}" >> "${_CMB_INC}/${h}" || return $?
                done
            fi
        done

        if [ -n "${LIPO_PATH}" ]; then
            # Set up variables to get our libraries to lipo
            PLATFORM_DIRS="$(find ${OBJDIR_ROOT} -type d -name "objdir-${PLATFORM}.*" -depth 1)"
            PLATFORM_LIBS="$(find ${PLATFORM_DIRS} -type d -name "lib" -depth 1)"
            FAT_OUTPUT="${COMBINED_ROOT}/lib"

            mkdir -p "${FAT_OUTPUT}" || return $?
            for l in $(find ${PLATFORM_LIBS} -type f -name '*.a' -exec basename {} \; | sort -u); do
                echo "Running lipo for library '${l}'..."
                ${LIPO_PATH} -create $(find ${PLATFORM_LIBS} -type f -name "${l}") -output "${FAT_OUTPUT}/${l}"
            done
        fi
    else
        print_usage "Missing/invalid target '${TARGET}'"
    fi
    return $?
}

do_clean() {
    if [ -n "${1}" ]; then
        echo "Cleaning up ${1} builds in \"${OBJDIR_ROOT}\"..."
        rm -rf "${OBJDIR_ROOT}/objdir-${1}" "${OBJDIR_ROOT}/objdir-${1}."*
    else
        echo "Cleaning up all builds in \"${OBJDIR_ROOT}\"..."
        rm -rf "${OBJDIR_ROOT}/objdir-"*  
    fi
    
    # Remove some leftovers (an empty OBJDIR_ROOT)
    rmdir "${OBJDIR_ROOT}" >/dev/null 2>&1
    return 0
}

do_copy_windows() {
    [ -d "${1}" ] || {
        print_usage "Invalid windows target directory:" "    \"${1}\""
        exit $?
    }
    for WIN_PLAT in $(ls "${1}" | grep 'objdir-windows'); do
        [ -d "${1}/${WIN_PLAT}" -a -d "${1}/${WIN_PLAT}/lib" ] && {
            echo "Copying ${WIN_PLAT}..."
            rm -rf "${OBJDIR_ROOT}/${WIN_PLAT}" || exit $?
            mkdir -p "${OBJDIR_ROOT}/${WIN_PLAT}" || exit $?
            cp -r "${1}/${WIN_PLAT}/lib" "${OBJDIR_ROOT}/${WIN_PLAT}/lib" || exit $?
            cp -r "${1}/${WIN_PLAT}/include" "${OBJDIR_ROOT}/${WIN_PLAT}/include" || exit $?
        } || {
            print_usage "Invalid build target:" "    \"${1}\""
            exit $?
        }
    done
}

do_combine_headers() {
    # Combine the headers into a top-level location
    COMBINED_HEADERS="${OBJDIR_ROOT}/include"
    rm -rf "${COMBINED_HEADERS}"
    mkdir -p "${COMBINED_HEADERS}" || return $?

    COMBINED_PLATS="${PKG_COMBINED_PLATS}"
    [ -n "${COMBINED_PLATS}" ] || {
        # list_plats last, so we get the right line endings
        COMBINED_PLATS="windows.x86_64 $(list_plats)"
    }
    for p in ${COMBINED_PLATS}; do
        _P_INC="${OBJDIR_ROOT}/objdir-${p}/include"
        if [ -d "${_P_INC}" ]; then
            cp -r "${_P_INC}/"* ${COMBINED_HEADERS} || return $?
        else
            echo "Platform ${p} has not been built"
            return 1
        fi
    done
    for h in ${PLATFORM_SPECIFIC_HEADERS}; do
        echo "Combining header '${h}'..."
        if [ -f "${COMBINED_HEADERS}/${h}" ]; then
            rm "${COMBINED_HEADERS}/${h}" || return $?
            for p in ${COMBINED_PLATS}; do
                _P_INC="${OBJDIR_ROOT}/objdir-${p}/include"
                if [ -f "${_P_INC}/${h}" ]; then
                    cat "${_P_INC}/${h}" >> "${COMBINED_HEADERS}/${h}" || return $?
                fi
            done
        fi
    done
    find "${OBJDIR_ROOT}/include" -type f -exec dos2unix {} \; || return $?
}

do_package() {
    [ -d "${1}" ] || {
        print_usage "Invalid package output directory:" "    \"${1}\""
        exit $?
    }
    
    # Combine the headers (checks that everything is already built)
    do_combine_headers || return $?
    
    # Build the tarball
    BASE="openssl-$(grep "OPENSSL_VERSION_TEXT" "${PATH_TO_OPENSSL_DIST}/include/openssl/opensslv.h" | \
                    cut -d'"' -f2- | cut -d' ' -f2)"
    cp -r "${OBJDIR_ROOT}" "${BASE}" || exit $?
    rm -rf "${BASE}/"*"/build" "${BASE}/logs" || exit $?
    rm -rf "${BASE}/objdir-macosx.x86_64" || return $?
    find "${BASE}" -name .DS_Store -exec rm {} \; || exit $?
    tar -zcvpf "${1}/${BASE}.tar.gz" "${BASE}" || exit $?
    rm -rf "${BASE}"
}

# Calculate the path to the openssl-dist repository
if [ -d "${1}" ]; then
    cd "${1}"
    PATH_TO_OPENSSL_DIST="$(pwd)"
    cd ->/dev/null
    shift 1
else
    PATH_TO_OPENSSL_DIST="${DEFAULT_OPENSSL_DIST}"
fi
[ -d "${PATH_TO_OPENSSL_DIST}" -a -f "${PATH_TO_OPENSSL_DIST}/Configure" ] || {
    print_usage "Invalid OpenSSL directory:" "    \"${PATH_TO_OPENSSL_DIST}\""
    exit $?
}

# Call bootstrap if that's what we specified
if [ "${1}" == "bootstrap" ]; then
    do_bootstrap ${2}
    exit $?
fi

# Call the appropriate function based on target
TARGET="${1}"; shift
case "${TARGET}" in
    "clean")
        do_clean "$@"
        ;;
    "copy-windows")
        do_copy_windows "$@"
        ;;
    "package")
        do_package "$@"
        ;;
    *)
        do_build ${TARGET} "$@"
        ;;
esac
exit $?

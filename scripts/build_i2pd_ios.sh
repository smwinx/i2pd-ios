#!/bin/bash
# i2pd iOS Build Script (device + simulator) aligned with official docs:
# https://docs.i2pd.website/en/latest/devs/building/ios/

set -euo pipefail

# Versions
I2PD_VERSION="2.58.0"
OPENSSL_VERSION="3.0.12"
BOOST_VERSION="1.84.0"
IOS_CMAKE_COMMIT="master" # keep in sync with https://github.com/vovasty/ios-cmake

# SDK / arch settings
IOS_MIN_VERSION="14.0"
DEVICE_ARCHS=(arm64)
SIM_ARCHS=(arm64 x86_64)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK_DIR="$SCRIPT_DIR/.build"
DEPS_DIR="$WORK_DIR/deps"
OUTPUT_DIR="$SCRIPT_DIR/output"

IOS_CMAKE_DIR="$DEPS_DIR/ios-cmake"
I2PD_SRC="$DEPS_DIR/i2pd"
OPENSSL_SRC="$DEPS_DIR/openssl-$OPENSSL_VERSION"
BOOST_SRC="$DEPS_DIR/boost_${BOOST_VERSION//./_}"

mkdir -p "$WORK_DIR" "$DEPS_DIR" "$OUTPUT_DIR/lib" "$OUTPUT_DIR/include"

echo "========================================"
echo "i2pd iOS Build Script"
echo "Versions: i2pd=$I2PD_VERSION, OpenSSL=$OPENSSL_VERSION, Boost=$BOOST_VERSION"
echo "Output:   $OUTPUT_DIR"
echo "========================================"

require_macos_tools() {
    if ! command -v xcrun >/dev/null 2>&1; then
        echo "Xcode Command Line Tools are required (xcrun not found)." >&2
        exit 1
    fi
}

fetch_sources() {
    if [ ! -d "$I2PD_SRC" ]; then
        echo "Cloning i2pd $I2PD_VERSION..."
        git -C "$DEPS_DIR" clone --depth 1 --branch "$I2PD_VERSION" https://github.com/PurpleI2P/i2pd.git
    fi

    if [ ! -d "$IOS_CMAKE_DIR" ]; then
        echo "Cloning ios-cmake ($IOS_CMAKE_COMMIT)..."
        git -C "$DEPS_DIR" clone https://github.com/vovasty/ios-cmake.git
        if [ "$IOS_CMAKE_COMMIT" != "master" ]; then
            git -C "$IOS_CMAKE_DIR" checkout "$IOS_CMAKE_COMMIT"
        fi
    fi

    if [ ! -d "$OPENSSL_SRC" ]; then
        echo "Fetching OpenSSL $OPENSSL_VERSION..."
        (cd "$DEPS_DIR" && curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" && tar xzf "openssl-$OPENSSL_VERSION.tar.gz")
    fi

    if [ ! -d "$BOOST_SRC" ]; then
        echo "Fetching Boost $BOOST_VERSION..."
        (cd "$DEPS_DIR" && curl -LO "https://boostorg.jfrog.io/artifactory/main/release/$BOOST_VERSION/source/boost_${BOOST_VERSION//./_}.tar.gz" && tar xzf "boost_${BOOST_VERSION//./_}.tar.gz")
    fi
}

build_openssl_platform() {
    local platform="$1"   # iphoneos or iphonesimulator
    local archs=(${@:2})
    local out_dir="$DEPS_DIR/openssl-$platform"

    echo "Building OpenSSL for $platform (${archs[*]})..."
    mkdir -p "$out_dir"
    pushd "$OPENSSL_SRC" >/dev/null

    make clean || true

    local target="ios64-xcrun"
    [[ "$platform" == "iphonesimulator" ]] && target="iossimulator-xcrun"

    ./Configure "$target" no-shared no-tests \
        --prefix="$out_dir" \
        -mios-version-min="$IOS_MIN_VERSION"

    # shellcheck disable=SC2046
    make -j$(sysctl -n hw.ncpu)
    make install_sw
    popd >/dev/null
}

build_boost_platform() {
    local platform="$1"   # iphoneos or iphonesimulator
    local archs=(${@:2})
    local out_dir="$DEPS_DIR/boost-$platform"
    local sdk_path
    sdk_path=$(xcrun --sdk "$platform" --show-sdk-path)

    echo "Building Boost for $platform (${archs[*]})..."
    mkdir -p "$out_dir"
    pushd "$BOOST_SRC" >/dev/null

    ./bootstrap.sh >/dev/null

    cat > user-config.jam << EOF
using darwin : ios : xcrun --sdk $platform clang++ : <striper> <root>$sdk_path ;
EOF

    # shellcheck disable=SC2046
    ./b2 -j$(sysctl -n hw.ncpu) \
        --user-config=user-config.jam \
        toolset=darwin-ios \
        target-os=iphone \
        address-model=64 \
        architecture=arm \
        link=static runtime-link=static \
        cflags="-fembed-bitcode -mios-version-min=$IOS_MIN_VERSION" \
        cxxflags="-std=c++17 -fembed-bitcode -mios-version-min=$IOS_MIN_VERSION" \
        stage --stagedir="$out_dir/stage" \
        --with-system --with-filesystem --with-program_options --with-date_time

    popd >/dev/null
}

lipo_boost_libs() {
    local libname
    for libname in libboost_system libboost_filesystem libboost_program_options libboost_date_time; do
        echo "Creating universal $libname.a"
        lipo -create \
            "$DEPS_DIR/boost-iphoneos/stage/lib/${libname}.a" \
            "$DEPS_DIR/boost-iphonesimulator/stage/lib/${libname}.a" \
            -output "$DEPS_DIR/boost-universal-${libname}.a"
    done
}

build_i2pd_platform() {
    local platform_cmake="$1" # OS or SIMULATOR64
    local platform_name="$2"  # iphoneos or iphonesimulator
    local build_dir="$WORK_DIR/build-$platform_name"

    echo "Configuring i2pd ($platform_name)..."
    mkdir -p "$build_dir"
    pushd "$build_dir" >/dev/null

    cmake "$I2PD_SRC/build" \
        -DIOS_PLATFORM="$platform_cmake" \
        -DPATCH=/usr/bin/patch \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$IOS_CMAKE_DIR/toolchain/iOS.cmake" \
        -DWITH_STATIC=yes \
        -DWITH_BINARY=no \
        -DBoost_INCLUDE_DIR="$DEPS_DIR/boost_${BOOST_VERSION//./_}" \
        -DBoost_LIBRARY_DIR="$DEPS_DIR/boost-$platform_name/stage/lib" \
        -DOPENSSL_INCLUDE_DIR="$DEPS_DIR/openssl-$platform_name/include" \
        -DOPENSSL_SSL_LIBRARY="$DEPS_DIR/openssl-$platform_name/lib/libssl.a" \
        -DOPENSSL_CRYPTO_LIBRARY="$DEPS_DIR/openssl-$platform_name/lib/libcrypto.a"

    # shellcheck disable=SC2046
    make -j$(sysctl -n hw.ncpu) VERBOSE=1
    popd >/dev/null
}

combine_universal_libs() {
    echo "Combining fat libraries..."
    libtool -static -o "$OUTPUT_DIR/lib/libi2pdclient.a" "$WORK_DIR"/build-*/libi2pdclient.a
    libtool -static -o "$OUTPUT_DIR/lib/libi2pd.a" "$WORK_DIR"/build-*/libi2pd.a

    # Combine wrapper if built for both platforms
    if [ -f "$WORK_DIR/wrapper-iphoneos/libi2pdwrapper.a" ] && [ -f "$WORK_DIR/wrapper-iphonesimulator/libi2pdwrapper.a" ]; then
        lipo -create "$WORK_DIR/wrapper-iphoneos/libi2pdwrapper.a" "$WORK_DIR/wrapper-iphonesimulator/libi2pdwrapper.a" -output "$OUTPUT_DIR/lib/libi2pdwrapper.a"
    fi

    # Dependencies (OpenSSL + Boost) into fat libs for convenience
    lipo -create "$DEPS_DIR/openssl-iphoneos/lib/libssl.a" "$DEPS_DIR/openssl-iphonesimulator/lib/libssl.a" -output "$OUTPUT_DIR/lib/libssl.a"
    lipo -create "$DEPS_DIR/openssl-iphoneos/lib/libcrypto.a" "$DEPS_DIR/openssl-iphonesimulator/lib/libcrypto.a" -output "$OUTPUT_DIR/lib/libcrypto.a"

    local libname
    for libname in libboost_system libboost_filesystem libboost_program_options libboost_date_time; do
        lipo -create "$DEPS_DIR/boost-iphoneos/stage/lib/${libname}.a" "$DEPS_DIR/boost-iphonesimulator/stage/lib/${libname}.a" -output "$OUTPUT_DIR/lib/${libname}.a"
    done
}

copy_headers() {
    echo "Copying headers..."
    mkdir -p "$OUTPUT_DIR/include/i2pd"
    cp -R "$I2PD_SRC/libi2pd" "$OUTPUT_DIR/include/" 2>/dev/null || true
    cp -R "$I2PD_SRC/libi2pd_client" "$OUTPUT_DIR/include/" 2>/dev/null || true
        cp -R "$I2PD_SRC/libi2pd_wrapper" "$OUTPUT_DIR/include/" 2>/dev/null || true
    cp -R "$DEPS_DIR/openssl-iphoneos/include/openssl" "$OUTPUT_DIR/include/" 2>/dev/null || true
    cp -R "$BOOST_SRC/boost" "$OUTPUT_DIR/include/" 2>/dev/null || true
}

    build_wrapper_platform() {
        local platform_name="$1"   # iphoneos or iphonesimulator
        local build_dir="$WORK_DIR/wrapper-$platform_name"
        local sdk_path
        sdk_path=$(xcrun --sdk "$platform_name" --show-sdk-path)

        echo "Building i2pd wrapper for $platform_name..."
        mkdir -p "$build_dir"
        pushd "$I2PD_SRC/libi2pd_wrapper" >/dev/null

        local cxx
        cxx=$(xcrun --sdk "$platform_name" --find clang++)
        local cflags="-std=c++17 -fembed-bitcode -O2 -mios-version-min=$IOS_MIN_VERSION -isysroot $sdk_path"
        local includes="-I$I2PD_SRC/libi2pd -I$I2PD_SRC/libi2pd_client -I$DEPS_DIR/openssl-$platform_name/include -I$BOOST_SRC"

        rm -f "$build_dir"/*.o
        for src in *.cpp; do
            [ -f "$src" ] || continue
            obj="$build_dir/${src%.cpp}.o"
            echo "  compiling $src"
            "$cxx" $cflags $includes -c "$src" -o "$obj"
        done

        libtool -static -o "$build_dir/libi2pdwrapper.a" "$build_dir"/*.o
        popd >/dev/null
    }

main() {
    require_macos_tools
    fetch_sources

    build_openssl_platform iphoneos "${DEVICE_ARCHS[@]}"
    build_openssl_platform iphonesimulator "${SIM_ARCHS[@]}"

    build_boost_platform iphoneos "${DEVICE_ARCHS[@]}"
    build_boost_platform iphonesimulator "${SIM_ARCHS[@]}"

    build_i2pd_platform SIMULATOR64 iphonesimulator
    build_i2pd_platform OS iphoneos

        build_wrapper_platform iphoneos
        build_wrapper_platform iphonesimulator

    combine_universal_libs
    copy_headers

    echo "========================================"
    echo "Build completed"
    echo "Artifacts:"
    ls -1 "$OUTPUT_DIR/lib"
    echo "Headers:  $OUTPUT_DIR/include"
    echo "========================================"
    echo "Next steps (per upstream docs):"
    echo "  • Link libi2pd.a and libi2pdclient.a plus libssl/libcrypto and Boost libs in Xcode"
    echo "  • Add $OUTPUT_DIR/include to Header Search Paths"
    echo "  • Add libc++ and libz system libs"
}

main "$@"

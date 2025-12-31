#!/bin/bash
# i2pd iOS Build Script
# Builds i2pd as a static library for iOS

set -e

I2PD_VERSION="2.50.2"
OPENSSL_VERSION="3.0.12"
BOOST_VERSION="1.84.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/output"

# iOS SDK settings
IOS_MIN_VERSION="14.0"

# Architectures
ARCHS="arm64"

echo "========================================"
echo "i2pd iOS Static Library Build Script"
echo "========================================"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR/lib"
mkdir -p "$OUTPUT_DIR/include"

# Clone i2pd if not present
if [ ! -d "$BUILD_DIR/i2pd" ]; then
    echo "Cloning i2pd..."
    git clone --depth 1 --branch $I2PD_VERSION https://github.com/PurpleI2P/i2pd.git "$BUILD_DIR/i2pd"
fi

# Build OpenSSL for iOS
build_openssl() {
    echo "Building OpenSSL $OPENSSL_VERSION for iOS..."
    
    if [ ! -d "$BUILD_DIR/openssl-$OPENSSL_VERSION" ]; then
        cd "$BUILD_DIR"
        curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
        tar xzf "openssl-$OPENSSL_VERSION.tar.gz"
    fi
    
    cd "$BUILD_DIR/openssl-$OPENSSL_VERSION"
    
    export CROSS_TOP="$(xcrun --sdk iphoneos --show-sdk-platform-path)/Developer"
    export CROSS_SDK="$(xcrun --sdk iphoneos --show-sdk-path | xargs basename)"
    export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin:$PATH"
    
    ./Configure ios64-xcrun no-shared no-tests \
        --prefix="$BUILD_DIR/openssl-ios" \
        -mios-version-min=$IOS_MIN_VERSION
    
    make clean
    make -j$(sysctl -n hw.ncpu)
    make install_sw
    
    echo "OpenSSL build complete"
}

# Build Boost for iOS
build_boost() {
    echo "Building Boost $BOOST_VERSION for iOS..."
    
    BOOST_VERSION_UNDERSCORE="${BOOST_VERSION//./_}"
    
    if [ ! -d "$BUILD_DIR/boost_$BOOST_VERSION_UNDERSCORE" ]; then
        cd "$BUILD_DIR"
        curl -LO "https://boostorg.jfrog.io/artifactory/main/release/$BOOST_VERSION/source/boost_$BOOST_VERSION_UNDERSCORE.tar.gz"
        tar xzf "boost_$BOOST_VERSION_UNDERSCORE.tar.gz"
    fi
    
    cd "$BUILD_DIR/boost_$BOOST_VERSION_UNDERSCORE"
    
    # Bootstrap
    ./bootstrap.sh
    
    # Create user-config.jam for iOS
    cat > user-config.jam << EOF
using darwin : ios
: xcrun --sdk iphoneos clang++ -arch arm64 -mios-version-min=$IOS_MIN_VERSION -fembed-bitcode-marker
: <striper> <root>$(xcrun --sdk iphoneos --show-sdk-path)
;
EOF
    
    ./b2 -j$(sysctl -n hw.ncpu) \
        --user-config=user-config.jam \
        toolset=darwin-ios \
        target-os=iphone \
        architecture=arm \
        address-model=64 \
        link=static \
        runtime-link=static \
        --with-system \
        --with-filesystem \
        --with-program_options \
        --with-date_time \
        --prefix="$BUILD_DIR/boost-ios" \
        install
    
    echo "Boost build complete"
}

# Build i2pd static library
build_i2pd() {
    echo "Building i2pd static library for iOS..."
    
    cd "$BUILD_DIR/i2pd"
    
    # Create iOS makefile override
    cat > Makefile.ios << 'EOF'
CXX = xcrun --sdk iphoneos clang++
CXXFLAGS = -std=c++17 -O2 -arch arm64 -mios-version-min=14.0 \
           -DIOS -DMOBILE_BUILD \
           -I$(OPENSSL_INC) -I$(BOOST_INC) \
           -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path)

LDFLAGS = -arch arm64 \
          -L$(OPENSSL_LIB) -L$(BOOST_LIB) \
          -lssl -lcrypto \
          -lboost_system -lboost_filesystem -lboost_program_options -lboost_date_time \
          -framework Foundation -framework Security

SOURCES = $(wildcard libi2pd/*.cpp) $(wildcard libi2pd_client/*.cpp)
OBJECTS = $(SOURCES:.cpp=.o)

libi2pd.a: $(OBJECTS)
	$(AR) rcs $@ $^

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) libi2pd.a
EOF
    
    # Build
    make -f Makefile.ios \
        OPENSSL_INC="$BUILD_DIR/openssl-ios/include" \
        OPENSSL_LIB="$BUILD_DIR/openssl-ios/lib" \
        BOOST_INC="$BUILD_DIR/boost-ios/include" \
        BOOST_LIB="$BUILD_DIR/boost-ios/lib" \
        clean libi2pd.a
    
    echo "i2pd build complete"
}

# Copy output
copy_output() {
    echo "Copying output files..."
    
    # Copy libraries
    cp "$BUILD_DIR/i2pd/libi2pd.a" "$OUTPUT_DIR/lib/"
    cp "$BUILD_DIR/openssl-ios/lib/libssl.a" "$OUTPUT_DIR/lib/"
    cp "$BUILD_DIR/openssl-ios/lib/libcrypto.a" "$OUTPUT_DIR/lib/"
    cp "$BUILD_DIR/boost-ios/lib/"*.a "$OUTPUT_DIR/lib/"
    
    # Copy headers
    cp -r "$BUILD_DIR/i2pd/libi2pd" "$OUTPUT_DIR/include/"
    cp -r "$BUILD_DIR/i2pd/libi2pd_client" "$OUTPUT_DIR/include/"
    cp -r "$BUILD_DIR/openssl-ios/include/openssl" "$OUTPUT_DIR/include/"
    cp -r "$BUILD_DIR/boost-ios/include/boost" "$OUTPUT_DIR/include/"
    
    echo "Output copied to $OUTPUT_DIR"
}

# Create xcframework (for easier Xcode integration)
create_xcframework() {
    echo "Creating xcframework..."
    
    # Create module map
    mkdir -p "$OUTPUT_DIR/include/i2pd"
    cat > "$OUTPUT_DIR/include/i2pd/module.modulemap" << 'EOF'
module i2pd {
    umbrella header "i2pd.h"
    export *
    link "i2pd"
}
EOF
    
    # Create umbrella header
    cat > "$OUTPUT_DIR/include/i2pd/i2pd.h" << 'EOF'
#ifndef I2PD_H
#define I2PD_H

#ifdef __cplusplus
extern "C" {
#endif

// i2pd C API for FFI
int i2pd_init(const char* config_path);
int i2pd_start(void);
int i2pd_stop(void);
int i2pd_is_running(void);

// Router info
const char* i2pd_get_router_status(void);
const char* i2pd_get_router_info(void);
int i2pd_get_active_peers(void);
int i2pd_get_known_peers(void);
int i2pd_get_active_tunnels(void);

// Bandwidth
long i2pd_get_bandwidth_in(void);
long i2pd_get_bandwidth_out(void);
long i2pd_get_transit_bandwidth(void);

// Tunnels
int i2pd_start_http_proxy(int port);
int i2pd_stop_http_proxy(void);
int i2pd_start_socks_proxy(int port);
int i2pd_stop_socks_proxy(void);

// Logs
const char* i2pd_get_logs(void);
void i2pd_clear_logs(void);

// Config
int i2pd_set_config(const char* key, const char* value);
const char* i2pd_get_config(const char* key);

#ifdef __cplusplus
}
#endif

#endif // I2PD_H
EOF
    
    echo "Headers created"
}

# Main build process
main() {
    echo "Starting build process..."
    
    # Check for Xcode
    if ! command -v xcrun &> /dev/null; then
        echo "Error: Xcode command line tools not found"
        exit 1
    fi
    
    build_openssl
    build_boost
    build_i2pd
    copy_output
    create_xcframework
    
    echo "========================================"
    echo "Build completed successfully!"
    echo "Output directory: $OUTPUT_DIR"
    echo "========================================"
    
    echo ""
    echo "Libraries built:"
    ls -la "$OUTPUT_DIR/lib/"
    
    echo ""
    echo "Next steps:"
    echo "1. Copy output/lib/*.a to your iOS project"
    echo "2. Copy output/include/* to your project's headers"
    echo "3. Link against the static libraries in Xcode"
}

main "$@"

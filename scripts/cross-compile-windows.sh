#!/bin/bash
set -euo pipefail

# Cross-compile go-curltest for Windows from Linux
# This script sets up the environment and dependencies needed for cross-compilation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORK_DIR="/tmp/curltest-cross-compile"

echo "=== Cross-compiling go-curltest for Windows ==="

# Create working directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Download and extract curl for Windows
CURL_VERSION="8.11.1_1"
CURL_ZIP="curl-${CURL_VERSION}-win64-mingw.zip"
CURL_URL="https://curl.se/windows/dl-${CURL_VERSION}/${CURL_ZIP}"

echo "Setting up curl for Windows cross-compilation..."

# Try multiple approaches to get curl for Windows
CURL_PREFIX=""

# Approach 1: Try to download prebuilt curl for Windows
echo "Attempting to download prebuilt curl for Windows..."
if curl -L -f -o "$CURL_ZIP" "$CURL_URL" 2>/dev/null; then
    echo "Downloaded prebuilt curl for Windows"
    unzip -q "$CURL_ZIP"
    
    # Find the extracted directory (name may vary)
    CURL_DIR=$(find . -maxdepth 1 -type d -name "curl-*" | head -1)
    if [ -n "$CURL_DIR" ]; then
        CURL_PREFIX="$WORK_DIR/$CURL_DIR"
        echo "Using prebuilt curl from: $CURL_PREFIX"
    fi
fi

# Approach 2: Build curl from source if prebuilt wasn't available
if [ -z "$CURL_PREFIX" ]; then
    echo "Building curl from source for Windows..."
    
    # Install additional dependencies that might be needed
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y autoconf automake libtool pkg-config || true
    fi
    
    # Download curl source
    CURL_SRC_VERSION="8.11.1"
    if curl -L -f -o "curl-${CURL_SRC_VERSION}.tar.gz" "https://curl.se/download/curl-${CURL_SRC_VERSION}.tar.gz" 2>/dev/null; then
        tar -xzf "curl-${CURL_SRC_VERSION}.tar.gz"
        cd "curl-${CURL_SRC_VERSION}"
        
        # Configure curl for Windows cross-compilation with minimal dependencies
        ./configure \
            --host=x86_64-w64-mingw32 \
            --prefix="$WORK_DIR/curl-win64" \
            --enable-static \
            --disable-shared \
            --without-ssl \
            --without-libssl-prefix \
            --disable-ldap \
            --disable-ldaps \
            --disable-rtsp \
            --disable-dict \
            --disable-telnet \
            --disable-tftp \
            --disable-pop3 \
            --disable-imap \
            --disable-smb \
            --disable-smtp \
            --disable-gopher \
            --disable-manual \
            --disable-ipv6 \
            --disable-ares \
            --without-libidn2 \
            --without-zlib \
            --without-brotli \
            --without-zstd
        
        make -j$(nproc)
        make install
        
        cd "$WORK_DIR"
        CURL_PREFIX="$WORK_DIR/curl-win64"
        echo "Built curl from source at: $CURL_PREFIX"
    else
        echo "Error: Could not download curl source"
        exit 1
    fi
fi

if [ -z "$CURL_PREFIX" ]; then
    echo "Error: Could not set up curl for Windows"
    exit 1
fi

echo "Using curl from: $CURL_PREFIX"

# Set up cross-compilation environment
export CC=x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++
export CGO_ENABLED=1
export GOOS=windows
export GOARCH=amd64

# Set CGO flags for static linking
export CGO_CFLAGS="-I${CURL_PREFIX}/include -DCURL_STATICLIB"

# Set up libraries for static linking - use minimal set for basic functionality
if [ -d "${CURL_PREFIX}/lib" ]; then
    # Check what libraries are actually available
    echo "Available libraries in ${CURL_PREFIX}/lib:"
    ls -la "${CURL_PREFIX}/lib" || true
    
    # Use a minimal set of Windows libraries for cross-compilation
    STATIC_LIBS=(
        "-L${CURL_PREFIX}/lib"
        "-lcurl"
        "-lws2_32"
        "-lcrypt32"
        "-luser32"
        "-lkernel32"
    )
    
    export CGO_LDFLAGS="${STATIC_LIBS[*]}"
else
    echo "Warning: curl lib directory not found at ${CURL_PREFIX}/lib"
    echo "Using system/minimal library set"
    export CGO_LDFLAGS="-lcurl -lws2_32 -lcrypt32 -luser32 -lkernel32"
fi

echo "Environment setup:"
echo "  CC=$CC"
echo "  CGO_ENABLED=$CGO_ENABLED"
echo "  GOOS=$GOOS"
echo "  GOARCH=$GOARCH"
echo "  CGO_CFLAGS=$CGO_CFLAGS"
echo "  CGO_LDFLAGS=$CGO_LDFLAGS"

# Build the application
echo "Building go-curltest for Windows..."
cd "$PROJECT_ROOT"

# Build with verbose output to help with debugging
go build -v -ldflags="-s -w" -o curltest.exe .

echo "=== Cross-compilation completed ==="
echo "Windows executable: curltest.exe"

# Show file information
ls -la curltest.exe
file curltest.exe

echo ""
echo "To test the executable, copy it to a Windows machine along with any required DLLs."
echo "If built statically, it should run without additional dependencies."
#!/bin/bash
set -euo pipefail

# Build curl from source for Windows cross-compilation
# This script is used when prebuilt curl for Windows is not available

WORK_DIR="${1:-/tmp/curl-build}"
PREFIX="${2:-${WORK_DIR}/curl-win64}"

echo "Building curl from source for Windows cross-compilation..."
echo "Work directory: $WORK_DIR"
echo "Install prefix: $PREFIX"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Install build dependencies if available
if command -v apt-get >/dev/null 2>&1; then
    echo "Installing build dependencies..."
    sudo apt-get update -q
    sudo apt-get install -y \
        autoconf \
        automake \
        libtool \
        pkg-config \
        make \
        || echo "Warning: Some dependencies might not be available"
fi

# Download curl source
CURL_VERSION="8.11.1"
CURL_TARBALL="curl-${CURL_VERSION}.tar.gz"
CURL_URL="https://curl.se/download/${CURL_TARBALL}"

echo "Downloading curl source..."
if command -v wget >/dev/null 2>&1; then
    wget -O "$CURL_TARBALL" "$CURL_URL" || {
        echo "Error: Failed to download curl source with wget"
        exit 1
    }
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "$CURL_TARBALL" "$CURL_URL" || {
        echo "Error: Failed to download curl source with curl"
        exit 1
    }
else
    echo "Error: Neither wget nor curl available for downloading"
    exit 1
fi

echo "Extracting curl source..."
tar -xzf "$CURL_TARBALL"
cd "curl-${CURL_VERSION}"

echo "Configuring curl for Windows cross-compilation..."
# Configure with minimal dependencies to avoid complex cross-compilation issues
./configure \
    --host=x86_64-w64-mingw32 \
    --prefix="$PREFIX" \
    --enable-static \
    --disable-shared \
    --without-ssl \
    --without-libssl-prefix \
    --without-gnutls \
    --without-mbedtls \
    --without-wolfssl \
    --without-schannel \
    --without-secure-transport \
    --without-amissl \
    --without-zlib \
    --without-brotli \
    --without-zstd \
    --without-libpsl \
    --without-libidn2 \
    --without-libssh2 \
    --without-nghttp2 \
    --without-nghttp3 \
    --without-ngtcp2 \
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
    --disable-threaded-resolver \
    --disable-verbose

echo "Building curl..."
make -j$(nproc) V=1

echo "Installing curl..."
make install

echo "Curl build completed successfully!"
echo "Curl installed to: $PREFIX"
echo "Include headers: $PREFIX/include"
echo "Static libraries: $PREFIX/lib"

# Verify the build
if [ -f "$PREFIX/lib/libcurl.a" ]; then
    echo "✓ Static library created: $PREFIX/lib/libcurl.a"
    ls -la "$PREFIX/lib/libcurl.a"
else
    echo "✗ Static library not found!"
    exit 1
fi

if [ -f "$PREFIX/include/curl/curl.h" ]; then
    echo "✓ Headers installed: $PREFIX/include/curl/curl.h"
    ls -la "$PREFIX/include/curl/"
else
    echo "✗ Headers not found!"
    exit 1
fi

echo "Curl for Windows cross-compilation is ready!"
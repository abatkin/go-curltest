# go-curltest
This is a sample/test app for using libcurl in Go via the [go-curl](https://github.com/andelf/go-curl) library. It isn't meant to be pretty, it's just meant to make it easy to exercise the library to test it out on different platforms and in different configurations.

## Contributions

If you have additional suggestions, corrections or other improvements, please let me know!

## Windows
Making this work on Windows is challenging. Here is a rough outline of what I may have done to make it work:

### Get cURL for Windows
I chose to download [curl for Windows](https://curl.se/windows/) and I extracted it to `c:\curl`. You can test that it is working properly by running:

```
c:\curl\bin\curl.exe -v https://www.google.com/
```

### Install msys and mingw

In order to build this, you cgo will need to work. I installed [msys2](https://www.msys2.org/), launched then ran a few extra commands to make sure it was up-to-date and had some extra tools installed:

```shell
pacman -Suy # Update itself
pacman -S mingw-w64-x86_64-gcc
pacman -S make zip unzip
```

From this point on, I used the **MSYS2 MINGW64** shell.

### Building

I want to build a static binary.

First, I needed to set up some environment variables:

```shell
export PATH="/c/Program Files/Go/bin:$PATH" # or whever you installed go
export CC=x86_64-w64-mingw32-gcc
export CGO_ENABLED=1
export CGO_CFLAGS="-static -IC:/curl/include -DCURL_STATICLIB"
export CGO_LDFLAGS="-static -LC:/curl/lib -lcurl -lssl -lcrypto -lz -lzstd -lnghttp2 -lnghttp3 -lngtcp2 -lngtcp2_crypto_quictls -lbrotlidec -lbrotlicommon -lssh2 -lpsl -lws2_32 -lcrypt32 -lbcrypt -lssl -lcrypto -lWldap32 -luser32 -lkernel32"
```

You can now build. I would recommend building with `go build -v -x .` so you will know how/why it is breaking.

The last 2 CGO options were challenging to figure out. The discussion in [curl/curl#5308](https://github.com/curl/curl/issues/5308) was helpful in figuring out that it needed `-DCURL_STATICLIB`. All of the libraries in the LDFLAGS was a little trial and error. And I expect it may change in the future or may be different depending on your build of curl.

I started with a few libraries based on what I had seen other people use (`-lcurl -lssl -lcrypto -lz -lws2_32 -lcrypt32 -lbcrypt -lssl -lcrypto -luser32 -lkernel32`) and then added additional libraries based on linker errors and the most likely candidate in `c:\curl\lib`. `-lWldap32` was a little more challenging, but...now you know.

### GitHub Actions

The repository includes an example workflow that builds on Windows using
[msys2/setup-msys2](https://github.com/msys2/setup-msys2). The workflow installs
`mingw-w64-x86_64-gcc` and `mingw-w64-x86_64-curl` via `pacman`. It then runs the
build inside the msys2 environment. Because Go is installed outside msys2, the
workflow captures the `GOROOT` from the Windows environment and prepends it to
the msys2 shell `PATH` before running `go build`. You can see the exact steps in
`.github/workflows/build.yml`.

## Cross-compiling for Windows from Linux

This repository also supports cross-compiling Windows binaries from a Linux environment. This can be useful for CI/CD pipelines or development environments where you want to build Windows executables without needing a Windows machine.

### Prerequisites

You'll need to install the MinGW-w64 cross-compiler and related tools:

```bash
# On Ubuntu/Debian:
sudo apt-get update
sudo apt-get install -y \
    mingw-w64 \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    wget \
    unzip
```

### Manual Cross-compilation

The repository includes a cross-compilation script that handles the entire process:

```bash
./scripts/cross-compile-windows.sh
```

This script will:

1. **Download curl for Windows**: Attempts to download pre-built curl libraries from [curl.se/windows](https://curl.se/windows/)
2. **Fallback to building from source**: If download fails, builds curl from source using the MinGW-w64 cross-compiler
3. **Set up environment**: Configures all necessary CGO environment variables for cross-compilation
4. **Build the executable**: Produces a statically-linked `curltest.exe` for Windows

### Manual Steps

If you prefer to understand the process step-by-step:

#### 1. Set up curl for Windows

```bash
# Create working directory
mkdir -p /tmp/curl-windows && cd /tmp/curl-windows

# Option A: Download prebuilt curl (if available)
curl -L -o curl-win64-mingw.zip "https://curl.se/windows/dl-8.11.1_1/curl-8.11.1_1-win64-mingw.zip"
unzip curl-win64-mingw.zip
export CURL_PREFIX="/tmp/curl-windows/curl-8.11.1_1-win64-mingw"

# Option B: Build curl from source (fallback)
curl -L -o curl-8.11.1.tar.gz "https://curl.se/download/curl-8.11.1.tar.gz"
tar -xzf curl-8.11.1.tar.gz
cd curl-8.11.1

./configure \
    --host=x86_64-w64-mingw32 \
    --prefix="/tmp/curl-windows/curl-win64" \
    --enable-static \
    --disable-shared \
    --without-ssl \
    --disable-ldap \
    --disable-ldaps

make -j$(nproc)
make install
export CURL_PREFIX="/tmp/curl-windows/curl-win64"
```

#### 2. Set up cross-compilation environment

```bash
export CC=x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++
export CGO_ENABLED=1
export GOOS=windows
export GOARCH=amd64
export CGO_CFLAGS="-I${CURL_PREFIX}/include -DCURL_STATICLIB"
export CGO_LDFLAGS="-L${CURL_PREFIX}/lib -lcurl -lws2_32 -lcrypt32 -luser32 -lkernel32"
```

#### 3. Build the application

```bash
go build -v -ldflags="-s -w" -o curltest.exe .
```

The resulting `curltest.exe` should be a statically-linked Windows executable that can run on Windows systems without requiring additional DLL files.

#### Troubleshooting Cross-compilation

- **Linker errors**: You may need to adjust the `CGO_LDFLAGS` to include additional Windows libraries depending on the curl build configuration
- **Missing headers**: Ensure the curl headers are properly installed in the prefix directory
- **SSL support**: The example above builds curl without SSL to simplify the cross-compilation. For SSL support, you'll need to cross-compile OpenSSL as well

### GitHub Action for Cross-compilation

The repository includes a GitHub Action workflow (`.github/workflows/cross-compile-windows.yml`) that automatically cross-compiles Windows binaries from Linux. This workflow:

- Sets up a Linux environment with MinGW-w64 cross-compiler
- Downloads or builds curl for Windows
- Cross-compiles the application
- Uploads the Windows executable as a build artifact

This approach demonstrates how to set up cross-compilation entirely from a Linux environment without using pre-built actions, as requested in the issue.

## Certificates

Depending on your libcurl build/configuration, there may not be any default certificates available. The test application lets you pass in a certificate store (`--certificates`) or will check the (relatively standard) environment variables `CURL_CA_BUNDLE` and `SSL_CERT_FILE`.


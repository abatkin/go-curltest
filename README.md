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

## Certificates

Depending on your libcurl build/configuration, there may not be any default certificates available. The test application lets you pass in a certificate store (`--certificates`) or will check the (relatively standard) environment variables `CURL_CA_BUNDLE` and `SSL_CERT_FILE`.


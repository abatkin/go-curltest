export CC=x86_64-w64-mingw32-gcc
export CGO_ENABLED=1
export CGO_CFLAGS="-static -I/curl/include -DCURL_STATICLIB"
export CGO_LDFLAGS="-static -L/curl/lib -lcurl -lssl -lcrypto -lz -lzstd -lnghttp2 -lnghttp3 -lngtcp2 -lngtcp2_crypto_quictls -lbrotlidec -lbrotlicommon -lssh2 -lpsl -lws2_32 -lcrypt32 -lbcrypt -lssl -lcrypto -luser32 -lsecur32 -lwldap32 -liphlpapi -lkernel32"
export GOOS=windows
export GOARCH=amd64

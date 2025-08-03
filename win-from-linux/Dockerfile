FROM public.ecr.aws/amazonlinux/amazonlinux:2023
ARG LLVM_MINGW_VERSION=20250730
ARG GO_VERSION=1.24.5
ARG CURL_VERSION=8.15.0_4

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN dnf groupinstall -y 'Development Tools'

WORKDIR /llvm-mingw
RUN curl -s -L https://github.com/mstorsjo/llvm-mingw/releases/download/${LLVM_MINGW_VERSION}/llvm-mingw-${LLVM_MINGW_VERSION}-ucrt-ubuntu-22.04-x86_64.tar.xz|tar -xJ --strip-components=1
ENV PATH="/llvm-mingw/bin:$PATH"

WORKDIR /
RUN curl -s -L https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -xz
ENV PATH="/go/bin:$PATH"

WORKDIR /root
RUN curl -s -L -O https://curl.se/windows/dl-${CURL_VERSION}/curl-${CURL_VERSION}-win64-mingw.zip && \
  unzip curl-${CURL_VERSION}-win64-mingw.zip && \
  rm curl-${CURL_VERSION}-win64-mingw.zip && \
  mv curl-${CURL_VERSION}-win64-mingw /curl

WORKDIR /workspace
COPY cross-vars.sh cross-vars.sh


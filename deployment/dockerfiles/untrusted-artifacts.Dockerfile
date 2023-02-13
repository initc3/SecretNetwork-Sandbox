# syntax=docker/dockerfile:1.4
#
# Dockerfile to build untrusted artifacts
#
# Available targets:
#
#   `--target enclave-ffi-types.h`` - image with compiled enclave-ffi-types.h
#   `--target compile-libgo_cosmwasm` - image with compiled libgo_cosmwasm.so
#   `--target compile-secretd` - image with compiled libgo_cosmwasm.so and secretd
#   `--target untrusted-artifacts` - scratch image with only libgo_cosmwasm.so & secretd
#                                    useful to copy the artifacts to the host machine

ARG TEST=enigmampc/rocksdb:v6.24.2
ARG SCRT_BASE_IMAGE_ENCLAVE=enigmampc/rocksdb:v6.24.2-1.1.5
ARG SCRT_RELEASE_BASE_IMAGE=enigmampc/enigma-sgx-base:2004-1.1.5


# ***************** GENERATE ENCLAVE FFI TYPES HEADER ************** #
FROM $SCRT_BASE_IMAGE_ENCLAVE AS enclave-ffi-types.h

RUN apt-get update &&  \
    apt-get install -y --no-install-recommends \
    clang-10 && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.cargo/bin:$PATH"

# Set working directory for the build
WORKDIR /go/src/github.com/enigmampc/SecretNetwork/

COPY rust-toolchain rust-toolchain
RUN rustup component add rust-src
RUN --mount=type=cache,target=/root/.cargo/registry cargo install xargo --version 0.3.25

# Add submodules
COPY third_party third_party

# Add source files
COPY cosmwasm cosmwasm/

# build header enclave-ffi-types.h needed by both librust_cosmwasm and libgo_cosmwasm
WORKDIR /go/src/github.com/enigmampc/SecretNetwork/cosmwasm/enclaves/ffi-types
RUN --mount=type=cache,target=/root/.cargo/registry \
    cargo check --features "build_headers"


# ***************** COMPILE UNTRUSTED libgo_cosmwasm.so ************** #
FROM enclave-ffi-types.h AS compile-libgo-cosmwasm

ARG BUILD_VERSION="v0.0.0"
ARG SGX_MODE=SW
ARG FEATURES
ARG FEATURES_U
ARG MITIGATION_CVE_2020_0551=LOAD

ENV VERSION=${BUILD_VERSION}
ENV SGX_MODE=${SGX_MODE}
ENV FEATURES=${FEATURES}
ENV FEATURES_U=${FEATURES_U}
ENV MITIGATION_CVE_2020_0551=${MITIGATION_CVE_2020_0551}

WORKDIR /go/src/github.com/enigmampc/SecretNetwork
COPY go-cosmwasm go-cosmwasm
WORKDIR /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm

RUN --mount=type=cache,target=/root/.cargo/registry \
    . /opt/sgxsdk/environment && env && \
    MITIGATION_CVE_2020_0551={MITIGATION_CVE_2020_0551} \
    VERSION=${VERSION} \
    FEATURES=${FEATURES} \
    FEATURES_U=${FEATURES_U} \
    SGX_MODE=${SGX_MODE} \
    make build-libgo-cosmwasm

ENTRYPOINT ["/bin/bash"]


# ***************** COMPILE UNTRUSTED SECRETD ************** #
FROM $TEST AS compile-secretd

ENV GOROOT=/usr/local/go
ENV GOPATH=/go/
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

ADD https://go.dev/dl/go1.19.linux-amd64.tar.gz go.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go.linux-amd64.tar.gz
RUN --mount=type=cache,target=/root/.cache/go-build \
    go install github.com/jteeuwen/go-bindata/go-bindata@latest && go-bindata -version

# Set working directory for the build
WORKDIR /go/src/github.com/enigmampc/SecretNetwork

ARG BUILD_VERSION="v0.0.0"
ARG SGX_MODE=SW
ARG FEATURES
ARG FEATURES_U
ARG DB_BACKEND=goleveldb
ARG CGO_LDFLAGS

ENV VERSION=${BUILD_VERSION}
ENV SGX_MODE=${SGX_MODE}
ENV FEATURES=${FEATURES}
ENV FEATURES_U=${FEATURES_U}
ENV CGO_LDFLAGS=${CGO_LDFLAGS}

# Add source files
COPY go-cosmwasm go-cosmwasm

# This is due to some esoteric docker bug with the underlying filesystem,
# so until I figure out a better way, this should be a workaround
RUN true
COPY x x
RUN true
COPY types types
RUN true
COPY app app
COPY go.mod .
COPY go.sum .
COPY cmd cmd
COPY Makefile .
RUN true
COPY client client

RUN go mod graph | awk '$1 !~ /@/ { print $2 }' | xargs -r go get

RUN ln -s /usr/lib/x86_64-linux-gnu/liblz4.so /usr/local/lib/liblz4.so && \
    ln -s /usr/lib/x86_64-linux-gnu/libzstd.so /usr/local/lib/libzstd.so

ARG IAS_BUILD=develop
RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/ias_keys/${IAS_BUILD}
RUN --mount=type=secret,id=SPID,dst=/run/secrets/spid.txt \
    cat /run/secrets/spid.txt \
    > /go/src/github.com/enigmampc/SecretNetwork/ias_keys/${IAS_BUILD}/spid.txt
RUN --mount=type=secret,id=API_KEY,dst=/run/secrets/api_key.txt \
    cat /run/secrets/api_key.txt \
    >  /go/src/github.com/enigmampc/SecretNetwork/ias_keys/${IAS_BUILD}/api_key.txt

RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release

COPY --from=compile-libgo-cosmwasm \
    /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so \
    /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so

RUN --mount=type=cache,target=/root/.cache/go-build \
    . /opt/sgxsdk/environment && env && \
    CGO_LDFLAGS=${CGO_LDFLAGS} \
    DB_BACKEND=${DB_BACKEND} \
    VERSION=${VERSION} \
    FEATURES=${FEATURES} \
    SGX_MODE=${SGX_MODE} \
    make build_local_no_rust


# ******************* COPY UNTRUSTED ARTIFACTS ******************** #
FROM scratch as untrusted-artifacts
COPY --from=compile-libgo-cosmwasm /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so .
COPY --from=compile-secretd /go/src/github.com/enigmampc/SecretNetwork/secretd .

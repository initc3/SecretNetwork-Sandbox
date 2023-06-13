#ARG TEST=enigmampc/rocksdb:v6.24.2
#ARG SCRT_BASE_IMAGE_ENCLAVE=enigmampc/rocksdb:v6.24.2-1.1.5
#ARG SCRT_RELEASE_BASE_IMAGE=enigmampc/enigma-sgx-base:2004-1.1.5
ARG SCRT_BASE_IMAGE_ENCLAVE=ghcr.io/scrtlabs/sgx-base:20.04-2.17-6.24.2
ARG SCRT_RELEASE_BASE_IMAGE=ghcr.io/scrtlabs/release-base:20.04-2.17

#FROM $SCRT_BASE_IMAGE_ENCLAVE as compile-contracts
#ENV PATH="/root/.cargo/bin:$PATH"
#FROM rust as contracts
#RUN apt-get update && apt-get install -y --no-install-recommends \
#        wabt \
#    && rm -rf /var/lib/apt/lists/*
#COPY hacking/contract-simple /usr/src/contract-simple
#WORKDIR /usr/src/contract-simple
#RUN make clean
#RUN --mount=type=cache,target=/root/.cargo/registry make
#
##FROM $SCRT_BASE_IMAGE_ENCLAVE as compile-contract-toy-swap
##ENV PATH="/root/.cargo/bin:$PATH"
#COPY hacking/contract-toy-swap /usr/src/contract-toy-swap
#WORKDIR /usr/src/contract-toy-swap
#RUN make clean
#RUN --mount=type=cache,target=/root/.cargo/registry make

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


# ***************** COMPILE ENCLAVE ************** #
FROM enclave-ffi-types.h AS compile-enclave

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

WORKDIR /go/src/github.com/enigmampc/SecretNetwork/cosmwasm/enclaves/execute

RUN cp ../target/headers/enclave-ffi-types.h ./
RUN --mount=type=cache,target=/root/.cargo/registry \
    . /opt/sgxsdk/environment && env && \
    MITIGATION_CVE_2020_0551={MITIGATION_CVE_2020_0551} \
    VERSION=${VERSION} \
    FEATURES=${FEATURES} \
    FEATURES_U=${FEATURES_U} \
    SGX_MODE=${SGX_MODE} \
    make librust_cosmwasm_enclave.signed.so

ENTRYPOINT ["/bin/bash"]

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


# ***************** COMPILE SECRETD ************** #

FROM $SCRT_BASE_IMAGE_ENCLAVE AS compile-secretd

ENV GOROOT=/usr/local/go
ENV GOPATH=/go/
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

ADD https://go.dev/dl/go1.19.linux-amd64.tar.gz go.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go.linux-amd64.tar.gz
RUN go install github.com/jteeuwen/go-bindata/go-bindata@latest && go-bindata -version

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

# This is due to some esoteric docker bug with the underlying filesystem, so until I figure out a better way, this should be a workaround
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

RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/

COPY --from=compile-libgo-cosmwasm \
    /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so \
    /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so

ARG IAS_BUILD=sw_dummy
RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/ias_keys/${IAS_BUILD}
RUN --mount=type=secret,id=SPID,dst=/run/secrets/spid.txt \
    cat /run/secrets/spid.txt \
    > /go/src/github.com/enigmampc/SecretNetwork/ias_keys/${IAS_BUILD}/spid.txt
RUN --mount=type=secret,id=API_KEY,dst=/run/secrets/api_key.txt \
    cat /run/secrets/api_key.txt \
    >  /go/src/github.com/enigmampc/SecretNetwork/ias_keys/${IAS_BUILD}/api_key.txt

RUN --mount=type=cache,target=/root/.cache/go-build \
    . /opt/sgxsdk/environment && env && \
    CGO_LDFLAGS=${CGO_LDFLAGS} \
    DB_BACKEND=${DB_BACKEND} \
    VERSION=${VERSION} \
    FEATURES=${FEATURES} \
    SGX_MODE=${SGX_MODE} \
    make build_local_no_rust


# ******************* RELEASE IMAGE ******************** #
FROM compile-secretd as release-image

# wasmi-sgx-test script requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
        #### Base utilities #### \
        jq \
        openssl \
        curl \
        wget \
        libsnappy-dev \
        libgflags-dev \
        bash-completion \
        wabt \
    && rm -rf /var/lib/apt/lists/*

RUN echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    npm i -g local-cors-proxy

ARG SGX_MODE=SW
ENV SGX_MODE=${SGX_MODE}

ARG SECRET_NODE_TYPE=NODE
ENV SECRET_NODE_TYPE=${SECRET_NODE_TYPE}

ENV PKG_CONFIG_PATH=""
ENV SCRT_ENCLAVE_DIR=/usr/lib/

# workaround because paths seem kind of messed up
RUN ln -s /opt/sgxsdk/lib64/libsgx_urts_sim.so /usr/lib/x86_64-linux-gnu/libsgx_urts_sim.so
RUN ln -s /opt/sgxsdk/lib64/libsgx_uae_service_sim.so /usr/lib/x86_64-linux-gnu/libsgx_uae_service_sim.so

COPY --from=compile-enclave \
    /go/src/github.com/enigmampc/SecretNetwork/cosmwasm/enclaves/execute/librust_cosmwasm_enclave.signed.so \
    /usr/lib/

# FIXME: Is this needed?
# Install ca-certificates
WORKDIR /root

# Copy over binaries from the build-env
RUN cp /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so /usr/lib/
RUN cp /go/src/github.com/enigmampc/SecretNetwork/secretd /usr/bin/secretd

RUN secretd completion > /root/secretd_completion

RUN echo "SECRET_NODE_TYPE=${SECRET_NODE_TYPE}" >> ~/.bashrc
RUN echo 'source /root/secretd_completion' >> ~/.bashrc

RUN mkdir -p /root/.secretd/.compute/
RUN mkdir -p /opt/secret/.sgx_secrets/
RUN mkdir -p /root/.secretd/.node/
RUN mkdir -p /root/config/


####### Node parameters
ARG MONIKER=default
ARG CHAINID=secretdev-1
ARG GENESISPATH=https://raw.githubusercontent.com/enigmampc/SecretNetwork/master/secret-testnet-genesis.json
ARG PERSISTENT_PEERS=201cff36d13c6352acfc4a373b60e83211cd3102@bootstrap.southuk.azure.com:26656

ENV GENESISPATH="${GENESISPATH}"
ENV CHAINID="${CHAINID}"
ENV MONIKER="${MONIKER}"
ENV PERSISTENT_PEERS="${PERSISTENT_PEERS}"

# Run secretd by default, omit entrypoint to ease using container with secretcli
ENTRYPOINT ["/bin/bash", "startup.sh"]

# ***************** BUILD_CONTRACTS ************** #
#FROM $SCRT_BASE_IMAGE_ENCLAVE as compile-contract-simple
#ENV PATH="/root/.cargo/bin:$PATH"
FROM rust as compile-contracts
RUN apt-get update && apt-get install -y --no-install-recommends \
        wabt \
    && rm -rf /var/lib/apt/lists/*
COPY hacking/contract-simple /root/contract-simple
WORKDIR /root/contract-simple
RUN make clean
RUN --mount=type=cache,target=/root/.cargo/registry make
COPY hacking/contract-toy-swap /root/contract-toy-swap
WORKDIR /root/contract-toy-swap
RUN make clean
RUN --mount=type=cache,target=/root/.cargo/registry make

FROM enigmampc/secret-contract-optimizer:1.0.4 as compile-sscrt-contract
COPY hacking/secretSCRT /contract

#RUN RUSTFLAGS='-C link-arg=-s' \
#        cargo build --release --target wasm32-unknown-unknown --locked && \
#        wasm-opt -Oz ./target/wasm32-unknown-unknown/release/*.wasm -o ./contract.wasm && \
#        cat ./contract.wasm | gzip -n -9 > ./contract.wasm.gz && \
#        rm -f ./contract.wasm
#--mount type=volume,source="$$(basename "$$(pwd)")_cache",target=/code/target \
#--mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \

# ***************** LOCALSECRET ************** #
FROM release-image as build-localsecret

ENV PATH="/root/.cargo/bin:$PATH"

COPY --from=compile-contracts /root/contract-simple /root/contract-simple
COPY --from=compile-contracts /root/contract-toy-swap /root/contract-toy-swap
#COPY --from=compile-sscrt-contract /contract/contract.wasm.gz /root/secretSCRT/contract.wasm.gz

WORKDIR /root

COPY deployment/docker/localsecret/faucet/faucet_server.js .

HEALTHCHECK --interval=5s --timeout=1s --retries=120 CMD bash -c 'curl -sfm1 http://localhost:26657/status && curl -s http://localhost:26657/status | jq -e "(.result.sync_info.latest_block_height | tonumber) > 0"'

COPY hacking/scripts ./scripts
RUN chmod +x ./scripts/startup.sh
RUN chmod +x ./scripts/bootstrap_init.sh
RUN chmod +x ./scripts/node_init.sh
RUN chmod +x ./scripts/set_init_states_toy_swap.sh

ENTRYPOINT ["./scripts/startup.sh"]


FROM scratch as secret-artifacts
COPY --from=compile-enclave \
    /go/src/github.com/enigmampc/SecretNetwork/cosmwasm/enclaves/execute/librust_cosmwasm_enclave.signed.so .
COPY --from=compile-libgo-cosmwasm \
    /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so .
COPY --from=compile-secretd /go/src/github.com/enigmampc/SecretNetwork/secretd .

# syntax=docker/dockerfile:1.4
# To try and avoid the dockerfile clutter I've included everything in this single file
# To use you want to choose a specific target based on your use case:
#
#   `--target release-image` - a full node docker image
#   `--target build-deb` - the image used to generate a .deb package
#   `--target build-deb-mainnet` - the image used to generate deb package for mainnet (will pull precompiled enclave)
#   `--target compile-secretd` - image with compiled enclave and secretd

ARG SCRT_BASE_IMAGE_SECRETD=enigmampc/rocksdb:v6.24.2-1.1.5
ARG TEST=enigmampc/rocksdb:v6.24.2
ARG SCRT_BASE_IMAGE_ENCLAVE=enigmampc/rocksdb:v6.24.2-1.1.5
ARG SCRT_RELEASE_BASE_IMAGE=enigmampc/enigma-sgx-base:2004-1.1.5

# ***************** PREPARE COMPILE ENCLAVE ************** #

FROM $SCRT_BASE_IMAGE_ENCLAVE AS prepare-compile-enclave

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
COPY go-cosmwasm go-cosmwasm/
COPY cosmwasm cosmwasm/

# ***************** COMPILE ENCLAVE ************** #

FROM prepare-compile-enclave AS compile-enclave

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

WORKDIR /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm

#RUN --mount=type=cache,target=/root/.cargo/registry  . /opt/sgxsdk/environment && env \
#    && MITIGATION_CVE_2020_0551={MITIGATION_CVE_2020_0551} VERSION=${VERSION} FEATURES=${FEATURES} FEATURES_U=${FEATURES_U} SGX_MODE=${SGX_MODE} make build-rust
RUN --mount=type=cache,target=/root/.cargo/registry . /opt/sgxsdk/environment && env && \
        MITIGATION_CVE_2020_0551={MITIGATION_CVE_2020_0551} \
        VERSION=${VERSION} \
        FEATURES=${FEATURES} \
        FEATURES_U=${FEATURES_U} \
        SGX_MODE=${SGX_MODE} \
        make build-enclave

#FROM compile-enclave as compile-libgo-cosmwasm
#RUN --mount=type=cache,target=/root/.cargo/registry . /opt/sgxsdk/environment && env && \
#RUN . /opt/sgxsdk/environment && \
#        FEATURES_U=${FEATURES_U} \
#        make build-libgo-cosmwasm

ENTRYPOINT ["/bin/bash"]

# ***************** COMPILE libgo_cosmwasm.so ************** #

#FROM prepare-compile-enclave AS compile-libgo-cosmwasm
FROM compile-enclave AS compile-libgo-cosmwasm

#ARG BUILD_VERSION="v0.0.0"
#ARG SGX_MODE=SW
#ARG FEATURES
#ARG FEATURES_U
#ARG MITIGATION_CVE_2020_0551=LOAD
#
#ENV VERSION=${BUILD_VERSION}
#ENV SGX_MODE=${SGX_MODE}
#ENV FEATURES=${FEATURES}
#ENV FEATURES_U=${FEATURES_U}
#ENV MITIGATION_CVE_2020_0551=${MITIGATION_CVE_2020_0551}
#
#WORKDIR /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm

#COPY --from=compile-enclave \
#    /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/librust_cosmwasm_enclave.signed.so .
#COPY --from=compile-enclave /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/lib .
#RUN --mount=type=cache,target=/root/.cargo/registry . /opt/sgxsdk/environment && env && \
RUN . /opt/sgxsdk/environment && \
        FEATURES_U=${FEATURES_U} \
        make build-libgo-cosmwasm

ENTRYPOINT ["/bin/bash"]

FROM scratch AS libgo_cosmwasm
COPY --from=compile-libgo-cosmwasm /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so .
#COPY --from=compile-enclave /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/librust_cosmwasm_enclave.signed.so /usr/lib/
#COPY --from=compile-enclave /go/src/github.com/enigmampc/SecretNetwork/secretd /usr/bin/secretd


# ***************** COMPILE SECRETD ************** #
FROM $TEST AS compile-secretd

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

RUN ln -s /usr/lib/x86_64-linux-gnu/liblz4.so /usr/local/lib/liblz4.so  && ln -s /usr/lib/x86_64-linux-gnu/libzstd.so /usr/local/lib/libzstd.so

RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/

COPY --from=compile-enclave /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so
COPY --from=compile-enclave /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/librust_cosmwasm_enclave.signed.so /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/librust_cosmwasm_enclave.signed.so
# COPY --from=compile-enclave /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/librust_cosmwasm_query_enclave.signed.so /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/librust_cosmwasm_query_enclave.signed.so

RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/ias_keys/develop
RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/ias_keys/sw_dummy
RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/ias_keys/production

RUN --mount=type=secret,id=SPID,dst=/run/secrets/spid.txt cat /run/secrets/spid.txt > /go/src/github.com/enigmampc/SecretNetwork/ias_keys/develop/spid.txt
RUN --mount=type=secret,id=SPID,dst=/run/secrets/spid.txt cat /run/secrets/spid.txt > /go/src/github.com/enigmampc/SecretNetwork/ias_keys/sw_dummy/spid.txt
RUN --mount=type=secret,id=SPID,dst=/run/secrets/spid.txt cat /run/secrets/spid.txt > /go/src/github.com/enigmampc/SecretNetwork/ias_keys/production/spid.txt

RUN --mount=type=secret,id=API_KEY,dst=/run/secrets/api_key.txt cat /run/secrets/api_key.txt > /go/src/github.com/enigmampc/SecretNetwork/ias_keys/develop/api_key.txt
RUN --mount=type=secret,id=API_KEY,dst=/run/secrets/api_key.txt cat /run/secrets/api_key.txt > /go/src/github.com/enigmampc/SecretNetwork/ias_keys/sw_dummy/api_key.txt
RUN --mount=type=secret,id=API_KEY,dst=/run/secrets/api_key.txt cat /run/secrets/api_key.txt >  /go/src/github.com/enigmampc/SecretNetwork/ias_keys/production/api_key.txt

RUN . /opt/sgxsdk/environment && env && CGO_LDFLAGS=${CGO_LDFLAGS} DB_BACKEND=${DB_BACKEND} VERSION=${VERSION} FEATURES=${FEATURES} SGX_MODE=${SGX_MODE} make build_local_no_rust
RUN . /opt/sgxsdk/environment && env && VERSION=${VERSION} FEATURES=${FEATURES} SGX_MODE=${SGX_MODE} make build_cli

FROM scratch as secret-artifacts
COPY --from=compile-libgo-cosmwasm /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so .
COPY --from=compile-enclave /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/librust_cosmwasm_enclave.signed.so /usr/lib/
COPY --from=compile-enclave /go/src/github.com/enigmampc/SecretNetwork/secretd /usr/bin/secretd

# ******************* RELEASE IMAGE ******************** #
FROM $SCRT_RELEASE_BASE_IMAGE as release-image

# wasmi-sgx-test script requirements
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    #### Base utilities ####
    jq \
    openssl \
    curl \
    wget \
    libsnappy-dev \
    libgflags-dev \
    bash-completion

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

# Install ca-certificates
WORKDIR /root

# Copy over binaries from the build-env
COPY --from=compile-secretd /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so /usr/lib/
COPY --from=compile-secretd /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/librust_cosmwasm_enclave.signed.so /usr/lib/
COPY --from=compile-secretd /go/src/github.com/enigmampc/SecretNetwork/secretd /usr/bin/secretd

COPY deployment/docker/testnet/bootstrap_init.sh .
COPY deployment/docker/testnet/node_init.sh .
COPY deployment/docker/testnet/startup.sh .
COPY deployment/docker/testnet/node_key.json .
COPY deployment/docker/localsecret/faucet/faucet_server.js .

RUN chmod +x /usr/bin/secretd
RUN chmod +x bootstrap_init.sh
RUN chmod +x startup.sh
RUN chmod +x node_init.sh

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

#ENV LD_LIBRARY_PATH=/opt/sgxsdk/libsgx-enclave-common/:/opt/sgxsdk/lib64/

# Run secretd by default, omit entrypoint to ease using container with secretcli
ENTRYPOINT ["/bin/bash", "startup.sh"]

# ***************** MAINNET UPGRADE ************** #

FROM release-image as mainnet-release

ARG BUILD_VERSION="v0.0.0"
ENV VERSION=${BUILD_VERSION}

RUN STORAGE_PATH=`echo ${VERSION} | sed -e 's/\.//g' | head -c 2` \
    && wget -O /usr/lib/librust_cosmwasm_enclave.signed.so https://engfilestorage.blob.core.windows.net/v$STORAGE_PATH/librust_cosmwasm_enclave.signed.so
RUN STORAGE_PATH=`echo ${VERSION} | sed -e 's/\.//g' | head -c 2` \
    && wget -O /usr/lib/libgo_cosmwasm.so https://engfilestorage.blob.core.windows.net/v$STORAGE_PATH/libgo_cosmwasm.so

COPY deployment/docker/mainnet/mainnet_node.sh .
RUN chmod +x mainnet_node.sh

ENTRYPOINT ["/bin/bash", "mainnet_node.sh"]

# ***************** BUILD DEBIAN ************** #
# ARG SCRT_COMPILED_BINARIES_SOURCE=compile-secretd
FROM compile-secretd as build-deb

ARG FEATURES
ARG FEATURES_U
ARG BUILD_VERSION="v0.5.0-rc1"
ARG SGX_MODE=SW
ENV VERSION=${BUILD_VERSION}
ENV SGX_MODE=${SGX_MODE}

# Install ca-certificates
WORKDIR /root

RUN mkdir -p ./go-cosmwasm/api/

COPY Makefile .

# Copy over binaries from the build-env
RUN cp /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/target/release/libgo_cosmwasm.so ./go-cosmwasm/api/
RUN cp /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm/librust_cosmwasm_enclave.signed.so ./go-cosmwasm/
RUN cp /go/src/github.com/enigmampc/SecretNetwork/secretd secretd
RUN cp /go/src/github.com/enigmampc/SecretNetwork/secretcli secretcli

COPY ./deployment/deb ./deployment/deb
COPY ./deployment/docker/builder/build_deb.sh .

RUN chmod +x build_deb.sh

# Run secretd by default, omit entrypoint to ease using container with secretcli
CMD ["/bin/bash", "build_deb.sh"]

# ***************** BUILD DEBIAN ************** #
# ARG SCRT_COMPILED_BINARIES_SOURCE=compile-secretd
FROM build-deb as build-deb-mainnet

COPY --from=mainnet-release /usr/lib/librust_cosmwasm_enclave.signed.so ./go-cosmwasm/

CMD ["/bin/bash", "build_deb.sh"]

# ***************** COMPILE CHECK-HW TOOL ************** #

FROM prepare-compile-enclave as compile-check-hw-tool

ARG BUILD_VERSION="v0.0.0"
ARG FEATURES
ARG FEATURES_U
ARG MITIGATION_CVE_2020_0551=LOAD

ENV VERSION=${BUILD_VERSION}
ENV FEATURES=${FEATURES}
ENV FEATURES_U=${FEATURES_U}
ENV MITIGATION_CVE_2020_0551=${MITIGATION_CVE_2020_0551}

WORKDIR /go/src/github.com/enigmampc/SecretNetwork/go-cosmwasm

# Ignore $FEATURES because it should never be `production`
RUN --mount=type=cache,target=/root/.cargo/registry  . /opt/sgxsdk/environment && env \
    && MITIGATION_CVE_2020_0551={MITIGATION_CVE_2020_0551} VERSION=${VERSION} FEATURES="" FEATURES_U=${FEATURES_U} SGX_MODE=HW make build-rust

# Set working directory for the build
WORKDIR /go/src/github.com/enigmampc/SecretNetwork/

# Add source files
COPY check-hw check-hw/
RUN cp go-cosmwasm/librust_cosmwasm_enclave.signed.so check-hw/check_hw_enclave.so

RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/ias_keys/develop
RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/ias_keys/sw_dummy
RUN mkdir -p /go/src/github.com/enigmampc/SecretNetwork/ias_keys/production

RUN --mount=type=secret,id=API_KEY,dst=/run/secrets/api_key.txt cat /run/secrets/api_key.txt > /go/src/github.com/enigmampc/SecretNetwork/ias_keys/develop/api_key.txt
RUN --mount=type=secret,id=API_KEY,dst=/run/secrets/api_key.txt cat /run/secrets/api_key.txt > /go/src/github.com/enigmampc/SecretNetwork/ias_keys/sw_dummy/api_key.txt
RUN --mount=type=secret,id=API_KEY,dst=/run/secrets/api_key.txt cat /run/secrets/api_key.txt >  /go/src/github.com/enigmampc/SecretNetwork/ias_keys/production/api_key.txt

WORKDIR /go/src/github.com/enigmampc/SecretNetwork/check-hw

COPY ./deployment/docker/builder/create_check_hw_tar.sh .

RUN --mount=type=cache,target=/root/.cargo/registry . /opt/sgxsdk/environment && env && make
RUN cp ../go-cosmwasm/librust_cosmwasm_enclave.signed.so ./check_hw_enclave.so

ENTRYPOINT ["/bin/bash", "create_check_hw_tar.sh"]

# ***************** LOCALSECRET ************** #
FROM release-image as build-localsecret

COPY deployment/docker/localsecret/bootstrap_init_no_stop.sh bootstrap_init.sh

RUN chmod +x bootstrap_init.sh

COPY deployment/docker/localsecret/faucet/faucet_server.js .

HEALTHCHECK --interval=5s --timeout=1s --retries=120 CMD bash -c 'curl -sfm1 http://localhost:26657/status && curl -s http://localhost:26657/status | jq -e "(.result.sync_info.latest_block_height | tonumber) > 0"'

ENTRYPOINT ["./bootstrap_init.sh"]

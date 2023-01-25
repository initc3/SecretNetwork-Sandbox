FROM rust:1.65

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        clang \
    && rm -rf /var/lib/apt/lists/*

# sgx sdk
ENV INTEL_SGX_URL "https://download.01.org/intel-sgx"
ENV LINUX_SGX_VERSION "2.17.1"
RUN set -eux; \
    distro="ubuntu20.04-server"; \
    pkg="sgx_linux_x64_sdk_2.17.101.1.bin"; \
    url="$INTEL_SGX_URL/sgx-linux/${LINUX_SGX_VERSION}/distro/${distro}/${pkg}"; \
    sha256="a9546afa218418c46a7a5262aa07748d940c686ebae0097e3f4c6d4c67985cda"; \
    wget -O sdk.bin "$url" --progress=dot:giga; \
    echo "$sha256 *sdk.bin" | sha256sum --strict --check -; \
    chmod +x sdk.bin; \
    echo -e 'no\n/opt' | ./sdk.bin; \
    echo 'source /opt/sgxsdk/environment' >> /root/.bashrc; \
    rm -f sdk.bin;

ARG SGX_MODE=SW
ENV SGX_MODE=${SGX_MODE}
ARG FEATURES="test"
ENV FEATURES=${FEATURES}

ENV SGX_SDK /opt/sgxsdk
ENV PATH $PATH:$SGX_SDK/bin:$SGX_SDK/bin/x64
ENV PKG_CONFIG_PATH $PKG_CONFIG_PATH:$SGX_SDK/pkgconfig
ENV LD_LIBRARY_PATH $SGX_SDK/sdk_libs

#ENV MITIGATION_CVE_2020_0551=LOAD

WORKDIR /enclave-test

COPY third_party third_party
COPY cosmwasm cosmwasm
COPY Makefile Makefile

COPY rust-toolchain rust-toolchain
RUN rustup component add rust-src clippy
RUN cargo install xargo --version 0.3.25

RUN --mount=type=secret,id=SPID,dst=/run/secrets/spid.txt cat /run/secrets/spid.txt > /enclave-test/cosmwasm/enclaves/execute/spid.txt
RUN --mount=type=secret,id=API_KEY,dst=/run/secrets/api_key.txt cat /run/secrets/api_key.txt > /enclave-test/cosmwasm/enclaves/execute/api_key.txt

CMD ["make", "enclave-tests"]

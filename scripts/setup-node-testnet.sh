#!/bin/bash

set -ex

username=`id -un`
scrt_home=${SCRT_HOME:-${HOME}/.secretd}
scrt_sgx_storage=${SCRT_SGX_STORAGE:-/opt/secret/.sgx_secrets}
scrt_enclave_dir=${SCRT_ENCLAVE_DIR:-/usr/lib}
printf -v date '%(%Y%m%d-%H%M%S)T' -1

exit_script() {
    echo "${username} must be stopped first before doing a state sync"
    echo -e "stop ${username} with:\n\tsudo systemctl stop ${username}"
    exit 1
}

backup() {
    mkdir -p ${scrt_home} ${HOME}/backups/${date}
    cp -r ${scrt_home} ${HOME}/backups/${date}/secretd
    rm -rf ${scrt_home}
    cp -r ${scrt_sgx_storage} ${HOME}/backups/${date}/sgx_secrets
    rm -rf ${scrt_sgx_storage}
}

init() {
    secretd --home ${scrt_home} init ${username} --chain-id pulsar-2
}

get_genesis_json() {
    wget -O ${scrt_home}/config/genesis.json "https://storage.googleapis.com/stakeordie-pulsar-2/genesis.json"
    echo "a48a5c2ba3f0d0ee077fc9a24514caaed3914e23e0de7b88163bb4d25e0866b8 ${scrt_home}/config/genesis.json" | sha256sum --check
}

update_ports() {
    # change ports in config.toml
    sed "s/6060/36060/" --in-place ${scrt_home}/config/config.toml
    sed "s/26656/36656/" --in-place ${scrt_home}/config/config.toml
    sed "s/26657/36657/" --in-place ${scrt_home}/config/config.toml
    sed "s/26658/36658/" --in-place ${scrt_home}/config/config.toml
    sed "s/26660/36660/" --in-place ${scrt_home}/config/config.toml
    
    # change ports in app.toml
    sed "s/1317/31317/" --in-place ${scrt_home}/config/app.toml
    sed "s/8080/38080/" --in-place ${scrt_home}/config/app.toml
    sed "s/9090/39090/" --in-place ${scrt_home}/config/app.toml
    sed "s/9091/39091/" --in-place ${scrt_home}/config/app.toml
}

auto_register() {
    mkdir -p ${SCRT_SGX_STORAGE}
    secretd --home ${scrt_home} auto-register --pulsar
}

configure() {
    secretd --home ${scrt_home} config chain-id pulsar-2
    secretd --home ${scrt_home} config node tcp://localhost:36657
    secretd --home ${scrt_home} config output json
}

optimize() {
    sed -i.bak -e "s/^contract-memory-enclave-cache-size *=.*/contract-memory-enclave-cache-size = \"15\"/" ${scrt_home}/config/app.toml
    perl -i -pe 's/^minimum-gas-prices = .+?$/minimum-gas-prices = "0.0125uscrt"/' ${scrt_home}/config/app.toml
}

set_seeds() {
    perl -i -pe 's/seeds = ""/seeds = "7a421a6f5f1618f7b6fdfbe4854985746f85d263\@108.62.104.102:26656,a72e376dca664bac55e8ce55a2e972a8ae2c995e\@144.202.126.98:26656,a941999e72f4726d276ef055a09cb8bedf8e7a9a\@45.35.77.30:26656,f95ba3da4a9eec559397f4b47b1539e24af6904c\@52.190.249.47:26656"/' ${scrt_home}/config/config.toml
}

set_persistent_peers() {
    perl -i -pe 's/persistent_peers = ""/persistent_peers = "7a421a6f5f1618f7b6fdfbe4854985746f85d263\@108.62.104.102:26656,a72e376dca664bac55e8ce55a2e972a8ae2c995e\@144.202.126.98:26656,a941999e72f4726d276ef055a09cb8bedf8e7a9a\@45.35.77.30:26656,f95ba3da4a9eec559397f4b47b1539e24af6904c\@52.190.249.47:26656"/' ${scrt_home}/config/config.toml
}

systemctl --quiet is-active ${username} && exit_script ||

backup
init
get_genesis_json
update_ports
auto-register
configure
optimize
set_seeds
set_persistent_peers

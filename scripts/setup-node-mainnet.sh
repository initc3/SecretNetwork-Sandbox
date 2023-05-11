#!/bin/bash

set -ex

network=${1}
ports_leading_digit=${PORTS_LEADING_DIGIT:-4}
tcp_endpoint=${TCP_ENDPOINT:-"tcp://localhost:${ports_leading_digit}6657"}
username=`id -un`
scrt_home=${SCRT_HOME:-${HOME}/.secretd}
scrt_sgx_storage=${SCRT_SGX_STORAGE:-/opt/secret/.sgx_secrets}
scrt_enclave_dir=${SCRT_ENCLAVE_DIR:-/usr/lib}
printf -v date '%(%Y%m%d-%H%M%S)T' -1

if [ ${network} == "testnet" ]; then
    chain_id="pulsar-2"
    genesis_url="https://storage.googleapis.com/stakeordie-pulsar-2/genesis.json"
    genesis_hash="a48a5c2ba3f0d0ee077fc9a24514caaed3914e23e0de7b88163bb4d25e0866b8"
    seeds="7a421a6f5f1618f7b6fdfbe4854985746f85d263\@108.62.104.102:26656,a72e376dca664bac55e8ce55a2e972a8ae2c995e\@144.202.126.98:26656,a941999e72f4726d276ef055a09cb8bedf8e7a9a\@45.35.77.30:26656,f95ba3da4a9eec559397f4b47b1539e24af6904c\@52.190.249.47:26656"
    persistent_peers="7a421a6f5f1618f7b6fdfbe4854985746f85d263\@108.62.104.102:26656,a72e376dca664bac55e8ce55a2e972a8ae2c995e\@144.202.126.98:26656,a941999e72f4726d276ef055a09cb8bedf8e7a9a\@45.35.77.30:26656,f95ba3da4a9eec559397f4b47b1539e24af6904c\@52.190.249.47:26656"
elif [ ${network} == "mainnet" ]; then
    chain_id="secret-4"
    genesis_url="https://github.com/scrtlabs/SecretNetwork/releases/download/v1.2.0/genesis.json"
    genesis_hash="759e1b6761c14fb448bf4b515ca297ab382855b20bae2af88a7bdd82eb1f44b9"
    seeds="6fb7169f7630da9468bf7cc0bcbbed1eb9ed0d7b@scrt-seed-01.scrtlabs.com:26656,ab6394e953e0b570bb1deeb5a8b387aa0dc6188a@scrt-seed-02.scrtlabs.com:26656,9cdaa5856e0245ecd73bd464308fb990fbc53b57@scrt-seed-03.scrtlabs.com:26656,20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:17156,ebc272824924ea1a27ea3183dd0b9ba713494f83@secret.mainnet.seed.autostake.net:26656"
    persistent_peers="6fb7169f7630da9468bf7cc0bcbbed1eb9ed0d7b@scrt-seed-01.scrtlabs.com:26656,ab6394e953e0b570bb1deeb5a8b387aa0dc6188a@scrt-seed-02.scrtlabs.com:26656,9cdaa5856e0245ecd73bd464308fb990fbc53b57@scrt-seed-03.scrtlabs.com:26656,20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:17156,ebc272824924ea1a27ea3183dd0b9ba713494f83@secret.mainnet.seed.autostake.net:26656,df808ad17d8c446253c68ea6503becec8604f38f@51.81.46.60:26656,f04a1e89a589d469c2807f1f6e15f1276439981a@20.228.250.21:26656"
else
    echo "NETWORK must be \"testnet\" or \"mainnet\". Got ${network}."
fi

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
    secretd --home ${scrt_home} init ${username} --chain-id $1
}

get_genesis_json() {
    wget -O ~/.secretd/config/genesis.json ${1}
    echo "${2} ${scrt_home}/config/genesis.json" | sha256sum --check
}

update_ports() {
    # change ports in config.toml
    sed "s/6060/${1}6060/" --in-place ${scrt_home}/config/config.toml
    sed "s/26656/${1}6656/" --in-place ${scrt_home}/config/config.toml
    sed "s/26657/${1}6657/" --in-place ${scrt_home}/config/config.toml
    sed "s/26658/${1}6658/" --in-place ${scrt_home}/config/config.toml
    sed "s/26660/${1}6660/" --in-place ${scrt_home}/config/config.toml
    
    # change ports in app.toml
    sed "s/1317/${1}1317/" --in-place ${scrt_home}/config/app.toml
    sed "s/8080/${1}8080/" --in-place ${scrt_home}/config/app.toml
    sed "s/9090/${1}9090/" --in-place ${scrt_home}/config/app.toml
    sed "s/9091/${1}9091/" --in-place ${scrt_home}/config/app.toml
}

auto_register() {
    mkdir -p ${SCRT_SGX_STORAGE}

    if [ ${network} == "testnet" ]; then
        secretd --home ${scrt_home} auto-register --pulsar
    elif [ ${network} == "mainnet" ]; then
        secretd --home ${scrt_home} auto-register
    else
	echo "NETWORK must be \"testnet\" or \"mainnet\". Got ${network}."
    fi
}

configure() {
    secretd --home ${scrt_home} config chain-id $1
    secretd --home ${scrt_home} config node $2
    secretd --home ${scrt_home} config output json
}

optimize() {
    sed -i.bak -e "s/^contract-memory-enclave-cache-size *=.*/contract-memory-enclave-cache-size = \"15\"/" ${scrt_home}/config/app.toml
    perl -i -pe 's/^minimum-gas-prices = .+?$/minimum-gas-prices = "0.0125uscrt"/' ${scrt_home}/config/app.toml
}

set_seeds() {
    perl -i -pe 's/seeds = ""/seeds = "${1}"/' ${scrt_home}/config/config.toml
}

set_persistent_peers() {
    perl -i -pe 's/persistent_peers = ""/persistent_peers = "${1}"/' ${scrt_home}/config/config.toml
}

systemctl --quiet is-active ${username} && exit_script ||

backup
init ${chain_id}
get_genesis_json ${genesis_url} ${genesis_hash}
update_ports ${ports_leading_digit}
auto-register
configure ${chain_id} ${tcp_endpoint}
optimize
set_seeds ${seeds}
set_persistent_peers ${persistent_peers}

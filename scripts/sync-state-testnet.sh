#!/bin/bash

set -ex

username=`id -un`
scrt_home=${SCRT_HOME:-${HOME}/.secretd}

exit_script() {
    echo "${username} must be stopped first before doing a state sync"
    echo -e "stop ${username} with:\n\tsudo systemctl stop ${username}"
    exit 1
}

edit_config() {
    snap_rpc="http://217.20.113.211:26657"
    block_height=$(curl -s ${snap_rpc}/block | jq -r .result.block.header.height | awk '{print $1 - ($1 % 2000)}'); \
    trust_hash=$(curl -s "${snap_rpc}/block?height=${block_height}" | jq -r .result.block_id.hash)

    sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
    	s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"http://37.58.59.45:26657,http://217.20.113.211:26657,http://46.165.245.170:26657,http://81.171.3.86:26657\"| ; \
    	s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1${block_height}| ; \
    	s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"${trust_hash}\"| ; \
    	s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" ${scrt_home}/config/config.toml
}

edit_config_app() {
    # set iavl-disable-fastnode = true
    sed "s/iavl-disable-fastnode = false/iavl-disable-fastnode = true/" -i ${scrt_home}/config/app.toml
    
    # snapshot interval
    sed "s/snapshot-interval = 0/snapshot-interval = 5000/" -i ${scrt_home}/config/app.toml
}

reset_tmp_dir() {
    #find /tmp/ -user ${username} | xargs rm -r
    cd /tmp
    ls -l | awk '$3=="${username}" { print $9 }' | xargs rm -rf
    cd $HOME
}

reset_data() {
    rm -rf ${scrt_home}/data
    rm -rf ${scrt_home}/.compute
    secretd --home ${scrt_home} tendermint unsafe-reset-all
    mkdir -p ${scrt_home}/data/snapshots
}

systemctl --quiet is-active $username && exit_script ||

edit_config_app
reset_tmp_dir
reset_data
edit_config

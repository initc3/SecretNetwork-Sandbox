#!/bin/bash

set -e

source ./scripts/log_utils.sh

verbose=${VERBOSE:-0}
COMPOSE_FILE=${COMPOSE_FILE:-compose.yml}

_help() {
   echo "Initialize a local secret network."
   echo
   echo "Syntax:  [-|h|v]"
   echo "options:"
   echo "h     Print this Help."
   echo "v     Verbose mode."
   echo
}

while getopts ":hv" option; do
    case $option in
        h)
            _help
            exit;;
        v)
            verbose=1;;
        \?)
            echo "Error: Invalid option"
            exit;;
    esac
done

export SN_VERBOSE=${verbose}

stop_network() {
    if [[ ${verbose} -eq 1 ]]; then
        docker compose --file ${COMPOSE_FILE} down --volumes --remove-orphans
    else
        docker compose --file ${COMPOSE_FILE} down --volumes --remove-orphans &>/dev/null
    fi
}

start_node() {
    if [[ ${verbose} -eq 1 ]]; then
        docker compose --file ${COMPOSE_FILE} up $1 -d
    else
        docker compose --file ${COMPOSE_FILE} up $1 -d &>/dev/null
    fi
}

stop_node() {
    if [[ ${verbose} -eq 1 ]]; then
        docker compose --file ${COMPOSE_FILE} stop $1
    else
        docker compose --file ${COMPOSE_FILE} stop $1 &>/dev/null
    fi
}

get_latest_block_height() {
    node=$1
    echo $(docker compose --file ${COMPOSE_FILE} exec ${node} \
        curl -s http://localhost:26657/status | \
        jq -e "(.result.sync_info.latest_block_height | tonumber)")
}

is_node_healthy() {
    node=$1
    block_height=$2
    echo $(docker compose --file ${COMPOSE_FILE} exec ${node} \
        curl -s http://localhost:26657/status | \
        jq -e "(.result.sync_info.latest_block_height | tonumber) > ${block_height}")
}

wait_for_blocks() {
    node=$1
    block_height=$2
    latest_block_height=$(get_latest_block_height localsecret-2)
    echo "Current block height for node 2: ${latest_block_height}"
    while [[ $(is_node_healthy localsecret-2 16) != "true" ]]
    do
        latest_block_height=$(get_latest_block_height localsecret-2)
        echo "Current block height for node 2: ${latest_block_height}"
        sleep 2
    done
}

start_network() {
    if [[ ${verbose} -eq 1 ]]; then
        docker compose --file ${COMPOSE_FILE} up localsecret-1 localsecret-2 -d
        docker compose --file ${COMPOSE_FILE} up block-watcher
    else
        docker compose --file ${COMPOSE_FILE} up localsecret-1 localsecret-2 -d &>/dev/null
        docker compose --file ${COMPOSE_FILE} up block-watcher
    fi

    docker compose --file ${COMPOSE_FILE} run --rm block-watcher teebox wait-for-blocks 14 --hostname localsecret-2
    docker_log localsecret-2 10

    echo
    docker compose --file ${COMPOSE_FILE} exec localsecret-2 teebox info-panel "Deploying the swap contract on-chain and initializing liquidity pools" --title "Toy Swap Contract Deployment"
    docker compose --file ${COMPOSE_FILE} exec localsecret-2 ./scripts/set_init_states_toy_swap.sh ${verbose}

    echo
    docker compose --file ${COMPOSE_FILE} exec localsecret-2 teebox info-panel "Deploying the SNIP20 contract on-chain" --title "SNIP20 Contract Deployment"
    docker compose --file ${COMPOSE_FILE} exec localsecret-2 ./scripts/setup_snip20.sh ${verbose}

    stop_node localsecret-1

    docker_log localsecret-2 5
}

print_status() {
    echo
    docker compose --file ${COMPOSE_FILE} exec localsecret-2 teebox info-panel "Secret Network Test Nodes are now setup, and ready for experiments" --title ":checkered_flag:"
    #echo
    #echo "*************************************************************************"
    #echo "*                                                                       *"
    #echo "*  Secret Network Test Nodes are now setup, and ready for experiments.  *"
    #echo "*                                                                       *"
    #echo "*************************************************************************"

    printf "\nNode 2 status info:\n"

    if command -v jq &> /dev/null
    then
        jq_cmd="jq"
    else
        jq_cmd="docker run -i --rm ghcr.io/jqlang/jq"
    fi

    docker compose --file ${COMPOSE_FILE} exec localsecret-2 secretd status | ${jq_cmd} .ValidatorInfo
}

stop_network
start_network
print_status

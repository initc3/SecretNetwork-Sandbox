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

export SN_VERBOSE=$verbose

#log() {
#    if [[ $verbose -eq 1 ]]; then
#        echo "$@"
#    fi
#}
#
#docker_log() {
#    if [[ $verbose -eq 1 ]]; then
#        docker compose --file ${COMPOSE_FILE} logs $1 --tail $2
#    fi
#}

stop_network() {
    if [[ $verbose -eq 1 ]]; then
        docker compose --file ${COMPOSE_FILE} down
    else
        docker compose --file ${COMPOSE_FILE} down &>/dev/null
    fi
}

start_node() {
    if [[ $verbose -eq 1 ]]; then
        docker compose --file ${COMPOSE_FILE} up $1 -d
    else
        docker compose --file ${COMPOSE_FILE} up $1 -d &>/dev/null
    fi
}

stop_node() {
    if [[ $verbose -eq 1 ]]; then
        docker compose --file ${COMPOSE_FILE} stop $1
    else
        docker compose --file ${COMPOSE_FILE} stop $1 &>/dev/null
    fi
}

start_network() {
    start_node localsecret-1
    #docker compose --file ${COMPOSE_FILE} up localsecret-1 -d
    sleep 5

    genesis=$(docker compose --file ${COMPOSE_FILE} exec localsecret-1 ls /genesis)
    while [[ "$genesis" != *"genesis.json"* ]]
    do
        log "Waiting for genesis file to be generated..."
        genesis=$(docker compose --file ${COMPOSE_FILE} exec localsecret-1 ls /genesis)
        docker_log localsecret-1 10
        #docker compose --file ${COMPOSE_FILE} logs localsecret-1 --tail 10
        sleep 5
    done

    start_node localsecret-2
    #docker compose --file ${COMPOSE_FILE} up localsecret-2 -d

    #waiting to build secretd and start node
    progs=$(docker compose --file ${COMPOSE_FILE} exec localsecret-2 ps -ef)
    while [[ "$progs" != *"secretd start --rpc.laddr tcp://0.0.0.0:26657"* ]]
    do
        log "Waiting for secretd build and node start..."
        progs=$(docker compose --file ${COMPOSE_FILE} exec localsecret-2 ps -ef)
        docker_log localsecret-2 10
        #docker compose --file ${COMPOSE_FILE} logs localsecret-2 --tail 10
        sleep 5
    done

    #waiting for blocks to start being produced before turning off localsecret-1
    logs=$(docker compose --file ${COMPOSE_FILE} logs localsecret-2 --tail 10)
    while [[ "$logs" != *"executed block"* ]]
    do
        log "Waiting for blocks to be produced..."
        logs=$(docker compose --file ${COMPOSE_FILE} logs localsecret-2 --tail 10)
        docker_log localsecret-2 10
        #docker compose --file ${COMPOSE_FILE} logs localsecret-2 --tail 10
        sleep 5
    done

    docker_log localsecret-2 10
    #docker compose --file ${COMPOSE_FILE} logs localsecret-2 --tail 10

    #./scripts/setup.sh
    docker compose --file ${COMPOSE_FILE} exec localsecret-2 ./scripts/set_init_states_toy_swap.sh $verbose
    docker compose --file ${COMPOSE_FILE} exec localsecret-2 ./scripts/setup_snip20.sh $verbose
    #docker-compose exec localsecret-2 ./debug_scripts/set_init_states_simple.sh

    stop_node localsecret-1
    #docker compose --file ${COMPOSE_FILE} stop localsecret-1

    docker_log localsecret-2 5
    #docker compose --file ${COMPOSE_FILE} logs localsecret-2 --tail 5
}

print_status() {
    echo
    echo "*************************************************************************"
    echo "*                                                                       *"
    echo "*  Secret Network Test Nodes are now setup, and ready for experiments.  *"
    echo "*                                                                       *"
    echo "*************************************************************************"

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

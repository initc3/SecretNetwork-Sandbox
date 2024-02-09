#!/bin/bash

log() {
    if [[ $SN_VERBOSE -eq 1 ]]; then
        echo "$@"
    fi
}

docker_log() {
    if [[ $SN_VERBOSE -eq 1 ]]; then
        docker compose logs $1 --tail $2  
    fi
}

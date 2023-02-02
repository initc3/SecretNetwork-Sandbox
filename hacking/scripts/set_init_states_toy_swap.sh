#!/bin/bash

set -e
set -x

source ./scripts/mev_utils.sh

prepare
query_balances
query_pools

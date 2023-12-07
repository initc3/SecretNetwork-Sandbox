#!/bin/bash

set -e

source ./scripts/mev_utils.sh

prepare
query_balances
query_pools

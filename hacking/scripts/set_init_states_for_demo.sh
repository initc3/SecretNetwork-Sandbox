#!/bin/bash

set -e
set -x

source ./scripts/demo_utils.sh

prepare
query_balances
query_pool pool_a
query_pool pool_b
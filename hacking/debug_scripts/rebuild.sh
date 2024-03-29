#!/usr/bin/env bash
set -e
set -x

### stop node
pkill -f "secretd start --rpc.laddr tcp://0.0.0.0:26657"

### recover from backup data
sleep 3
rm -rf /root/.secretd/.*
rm -rf /root/.secretd/*
cp -rf /root/hist_data/.secretd/. /root/.secretd/

### rebuild secretd
cd /go/src/github.com/enigmampc/SecretNetwork/
rm secretd
set -e
CGO_LDFLAGS=$CGO_LDFLAGS DB_BACKEND=goleveldb MITIGATION_CVE_2020_0551=LOAD VERSION=$VERSION FEATURES=$FEATURES SGX_MODE=$SGX_MODE make build_local_no_rust
chmod +x secretd
cp secretd /usr/bin/secretd
cd /root

### resume node
RUST_BACKTRACE=1 secretd start --rpc.laddr "tcp://0.0.0.0:26657" &
sleep infinity

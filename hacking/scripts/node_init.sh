#!/usr/bin/env bash
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~node_init~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

set -euo pipefail
set -x
export RPC_URL="localsecret-1:26657"
export CHAINID="secretdev-1"
file=/root/.secretd/config/started.txt
if [ ! -e "$file" ]
then
  echo "Starting from scratch~~~~~~~~~~~~~"

  mkdir -p /root/.secretd/.node
  secretd config keyring-backend test
  secretd config node "http://$RPC_URL"
  secretd config chain-id $CHAINID
  secretd config output json
  b_mnemonic="jelly shadow frog dirt dragon use armed praise universe win jungle close inmate rain oil canvas beauty pioneer chef soccer icon dizzy thunder meadow"
  echo "$b_mnemonic" | secretd keys add b --recover

  mkdir -p /root/.secretd/.node

  secretd init "$(hostname)" --chain-id $CHAINID || true

  PERSISTENT_PEERS="115aa0a629f5d70dd1d464bc7e42799e00f4edae@localsecret-1:26656"
  sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/g' ~/.secretd/config/config.toml
  sed -i 's/persistent_peers = ""/persistent_peers = "'$PERSISTENT_PEERS'"/g' ~/.secretd/config/config.toml
  sed -i 's/trust_period = "168h0m0s"/trust_period = "168h"/g' ~/.secretd/config/config.toml
  echo "Set persistent_peers: $PERSISTENT_PEERS"

  echo "Waiting for bootstrap to start..."
  sleep 5

  secretd q block 1

  secretd init-enclave --reset

  PUBLIC_KEY=$(secretd parse /opt/secret/.sgx_secrets/attestation_cert.der | cut -c 3- )

  echo "Public key: $PUBLIC_KEY"

  secretd parse /opt/secret/.sgx_secrets/attestation_cert.der
  ls /opt/secret/.sgx_secrets/attestation_cert.der
  secretd tx register auth /opt/secret/.sgx_secrets/attestation_cert.der -y --from b --broadcast-mode block --gas-prices 0.25uscrt > out
  cat out
  tx_hash="$(cat out | jq -r '.txhash')"

  sleep 5

  secretd q tx "$tx_hash"

  SEED="$(secretd q register seed "$PUBLIC_KEY" | cut -c 3-)"
  echo "SEED: $SEED"

  secretd q register secret-network-params

  secretd configure-secret node-master-cert.der "$SEED"

  cp /tmp/genesis/genesis.json /root/.secretd/config/genesis.json
  
  secretd validate-genesis
  RUST_BACKTRACE=1 secretd start --rpc.laddr tcp://0.0.0.0:26657 &> output &
  PID=$!
  echo "waiting for state sync to end.."
  sleep 5
  state_sync=$(secretd status | jq .SyncInfo.catching_up)
  echo "state_sync $state_sync"
  while [ $state_sync == "true" ];
  do
      sleep 5
      state_sync=$(secretd status | jq .SyncInfo.catching_up)
      echo "state_sync $state_sync"
  done

  kill $PID  
  cat output
  echo "joininng as validator now"
  secretd tx staking create-validator -y \
    --amount=100000000uscrt \
    --pubkey=$(secretd tendermint show-validator) \
    --details="To infinity and beyond!" \
    --commission-rate="0.10" \
    --commission-max-rate="0.20" \
    --commission-max-change-rate="0.01" \
    --min-self-delegation="1" \
    --moniker="hack0r" \
    --broadcast-mode block \
    --from=b > out2
  tx_hash="$(cat out2 | jq -r '.txhash')"
  sleep 10
  secretd q tx "$tx_hash" | jq .
  secretd q staking validators | grep moniker | jq .
  secretd q staking validators | grep moniker
  echo "started" > $file
  secretd config node "http://localhost:26657"
  # hack to change permission of data after starting node
  # sleep 10 && chmod -R ugo+rwx ~/.secretd/* &
else
  echo "Restarting node~~~~~~~~~~~~~"
  curr_dir=$(pwd)
  cd /go/src/github.com/enigmampc/SecretNetwork/
  # make build_cli
  make build_local_no_rust
  cp secretd /usr/bin/secretd
  chmod +x secretd
  cd $curr_dir
  # PERSISTENT_PEERS="115aa0a629f5d70dd1d464bc7e42799e00f4edae@localsecret-1:26656"
  # sed -i 's/persistent_peers = "'$PERSISTENT_PEERS'"/persistent_peers = ""/g' ~/.secretd/config/config.toml
  sed -i 's/pex = true/pex = false/g' ~/.secretd/config/config.toml
  sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/g' ~/.secretd/config/config.toml
  echo "Set pex = false"
  RUST_BACKTRACE=1 secretd start --rpc.laddr tcp://0.0.0.0:26657
fi
# sed -i 's/pex = true/pex = false/g' ~/.secretd/config/config.toml
# echo "Set pex = false"
# RUST_BACKTRACE=1 secretd start --rpc.laddr tcp://0.0.0.0:26657
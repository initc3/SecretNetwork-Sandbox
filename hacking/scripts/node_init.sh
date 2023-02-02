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
file=/root/.secretd/config/genesis.json
if [ ! -f "$file" ];then
  echo "Starting from scratch~~~~~~~~~~~~~"

  mkdir -p /root/.secretd/.node
  secretd config keyring-backend test
  secretd config node "http://$RPC_URL"
  secretd config chain-id $CHAINID
  secretd config output json

  a_mnemonic="grant rice replace explain federal release fix clever romance raise often wild taxi quarter soccer fiber love must tape steak together observe swap guitar"
  b_mnemonic="jelly shadow frog dirt dragon use armed praise universe win jungle close inmate rain oil canvas beauty pioneer chef soccer icon dizzy thunder meadow"
  c_mnemonic="chair love bleak wonder skirt permit say assist aunt credit roast size obtain minute throw sand usual age smart exact enough room shadow charge"
  d_mnemonic="word twist toast cloth movie predict advance crumble escape whale sail such angry muffin balcony keen move employ cook valve hurt glimpse breeze brick"

  echo $a_mnemonic | secretd keys add a --recover
  echo $b_mnemonic | secretd keys add b --recover
  echo $c_mnemonic | secretd keys add c --recover
  echo $d_mnemonic | secretd keys add d --recover

  mkdir -p /root/.secretd/.node
  #PERSISTENT_PEERS="115aa0a629f5d70dd1d464bc7e42799e00f4edae@localsecret-1:26656"
  secretd init "$(hostname)" --chain-id $CHAINID || true
  eval PEERID=$(secretd status | jq .NodeInfo.id)
  PERSISTENT_PEERS="$PEERID@localsecret-1:26656"
  sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/g' ~/.secretd/config/config.toml
  sed -i 's/persistent_peers = ""/persistent_peers = "'$PERSISTENT_PEERS'"/g' ~/.secretd/config/config.toml
  sed -i 's/trust_period = "168h0m0s"/trust_period = "168h"/g' ~/.secretd/config/config.toml
  echo "Set persistent_peers: $PERSISTENT_PEERS"

  secretd q block 1

  secretd init-enclave --reset

  PUBLIC_KEY=$(secretd parse /opt/secret/.sgx_secrets/attestation_cert.der | cut -c 3- )

  echo "Public key: $PUBLIC_KEY"

  secretd parse /opt/secret/.sgx_secrets/attestation_cert.der
  ls /opt/secret/.sgx_secrets/attestation_cert.der
  secretd tx register auth /opt/secret/.sgx_secrets/attestation_cert.der -y --from b --broadcast-mode sync --gas-prices 0.25uscrt > out
  cat out
  tx_hash="$(cat out | jq -r '.txhash')"

  sleep 5

  secretd q tx "$tx_hash"

  SEED="$(secretd q register seed "$PUBLIC_KEY" | cut -c 3-)"
  echo "SEED: $SEED"

  secretd q register secret-network-params

  secretd configure-secret node-master-cert.der "$SEED"

  cp /genesis/genesis.json /root/.secretd/config/genesis.json
  
  secretd validate-genesis
  RUST_BACKTRACE=1 secretd start --rpc.laddr tcp://0.0.0.0:26657 &
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
  cat /root/out
  secretd config node "http://localhost:26657"
  pkill -f secretd
  while [ $(secretd status) ];
  do
    sleep 5
  done  
else
  echo "$file exists restarting node"
fi
RUST_BACKTRACE=1 secretd start --rpc.laddr tcp://0.0.0.0:26657
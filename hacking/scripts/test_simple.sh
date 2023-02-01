#!/bin/bash
# set -x
ADDR=$(secretd keys show --address b)
CONTRACT_ADDRESS=$(cat CONTRACT_ADDRESS)

UNIQUE_LABEL=$(date '+%Y-%m-%d-%H:%M:%S')

num=10
for (( i = 0; i < $num; i++ )) do
    secretd tx compute snapshot --from b "snapshot-$i-$UNIQUE_LABEL" -y --broadcast-mode sync
    secretd tx compute delivertx tx_victim_sign.json --from $ADDR -y 
    secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" 

    eval STORE_1_VALUE=$(secretd q compute query $CONTRACT_ADDRESS "{\"store1_q\":{}}" )
    if [ "$STORE_1_VALUE" != "hello2" ]; then
        echo "$i ERROR: value in store_1 \"$STORE_1_VALUE\" != \"hello2\""
        exit 1
    fi
    echo "$i SUCCESS: value in store_1 \"$STORE_1_VALUE\" == \"hello2\""
done
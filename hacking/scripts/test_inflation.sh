set -x
set -e

SECRETD=secretd

ACC1='secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne'
ACC0='secret1ap26qrlp8mcq2pg6r47w43l0y8zkqm8a450s03'
ACC2='secret1kzwtde98vl0rx2lgellq34sjdw0dqcx6kg5cg3'
CONTRACT=$(cat contractAddress.txt)
AMOUNT='10'

sleep_time=2
cnt_max=5

start_secretd() {
    dev=$($SECRETD q account $ACC1)
    echo "$?"
}

query_tx_res() {
    dev=$($SECRETD q tx $1)
    echo "$?"
}

exec_transfer() {
    txhash=$($SECRETD tx compute execute $CONTRACT "{\"transfer\":{\"recipient\":\"$2\", \"amount\": \"$3\", \"memo\":\"\"}}" --from $1 -y | jq .txhash)
    txhash=${txhash:1:64}
    while true; do
        sleep $sleep_time
        if [ $(query_tx_res $txhash) == 0 ]; then break; fi
    done
    echo $($SECRETD q tx $txhash | jq .code)
}


cnt=0
while true; do
    sleep $sleep_time
    if [ $(start_secretd) != 0 ]; then break; fi
    if [ $((cnt%cnt_max)) == 0 ]; then (pkill -f secretd); fi
    ((cnt=cnt+1))
done

sleep 5
cp -rf backup/.secretd/. /root/.secretd/

cnt=0
while true; do
    sleep $sleep_time
    if [ $(start_secretd) == 0 ]; then break; fi
    if [ $((cnt%cnt_max)) == 0 ]; then (secretd start --rpc.laddr tcp://0.0.0.0:26657 >> log 2>&1 &); fi
    ((cnt=cnt+1))
done

sleep $sleep_time

res1=$(exec_transfer $ACC0 $ACC1 9999)
res2=$(exec_transfer $ACC0 $ACC1 9999)
res3=$(exec_transfer $ACC1 $ACC2 28000)

cnt=0
while true; do
    sleep $sleep_time
    if [ $(start_secretd) != 0 ]; then break; fi
    if [ $((cnt%cnt_max)) == 0 ]; then (pkill -f $SECRETD); fi
    ((cnt=cnt+1))
done

sleep $sleep_time

echo $res1 $res2 $res3




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

lo=0
hi=20
while [ $(expr $hi - $lo) -ne 0 ]; do
    midv=$(( (hi + lo ) / 2))
    echo $lo $hi $midv

	cp -rf backup/* /root/.secretd/
	
    $SECRETD start >> log 2>&1 &
    
    cnt=0
    while true; do
        ((cnt=cnt+1))
	    sleep $sleep_time
        if [ $(start_secretd) == 0 ]; then break; fi
        if [ $((cnt%cnt_max)) == 0 ]; then ($SECRETD start >> log 2>&1 &); fi
    done

    sleep $sleep_time

    txhash1=$($SECRETD tx compute execute $CONTRACT "{\"transfer\":{\"recipient\":\"$ACC0\", \"amount\": \"$midv\", \"memo\":\"\"}}" --from $ACC1 -y | jq .txhash)
    txhash1=${txhash1:1:64}

    cnt=0
    while true; do
        ((cnt=cnt+1))
        sleep $sleep_time
        if [ $(query_tx_res $txhash1) == 0 ]; then break; fi
        if [ $((cnt%cnt_max)) == 0 ]; then 
            txhash1=$($SECRETD tx compute execute $CONTRACT "{\"transfer\":{\"recipient\":\"$ACC0\", \"amount\": \"$midv\", \"memo\":\"\"}}" --from $ACC1 -y | jq .txhash)
            txhash1=${txhash1:1:64}
        fi
    done
    res1=$($SECRETD q tx $txhash1 | jq .code)

    txhash2=$($SECRETD tx compute execute $CONTRACT "{\"transfer\":{\"recipient\":\"$ACC2\", \"amount\": \"$AMOUNT\", \"memo\":\"\"}}" --from $ACC0 -y | jq .txhash)
    txhash2=${txhash2:1:64}
    
    cnt=0
    while true; do
        ((cnt=cnt+1))
        sleep $sleep_time
        if [ $(query_tx_res $txhash2) == 0 ]; then break; fi
        if [ $((cnt%cnt_max)) == 0 ]; then 
            txhash2=$($SECRETD tx compute execute $CONTRACT "{\"transfer\":{\"recipient\":\"$ACC2\", \"amount\": \"$AMOUNT\", \"memo\":\"\"}}" --from $ACC0 -y | jq .txhash)
            txhash2=${txhash2:1:64}
        fi
    done
    res2=$($SECRETD q tx $txhash2 | jq .code)

    pkill -f $SECRETD
    
    cnt=0
    while true; do
        ((cnt=cnt+1))
        sleep $sleep_time
        if [ $(start_secretd) != 0 ]; then break; fi
        if [ $((cnt%cnt_max)) == 0 ]; then (pkill -f $SECRETD); fi
    done
    
    sleep $sleep_time

  echo $res1 $res2

  if [ $res2 != 0 ]; then ((lo=midv+1)); else hi=$midv; fi
done
echo $lo



set -x
set -e

SECRETD=secretd

ADV='secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne'
SENDER='secret1ap26qrlp8mcq2pg6r47w43l0y8zkqm8a450s03'
RECEIVER='secret1kzwtde98vl0rx2lgellq34sjdw0dqcx6kg5cg3'
CONTRACT='secret18vd8fpwxzck93qlwghaj6arh4p7c5n8978vsyg'
AMOUNT='10'

sleep_time=2

start_secretd() {
    $SECRETD q account $ADV
    echo "$?"
}

query_tx_res() {
    $SECRETD q tx $1
    echo "$?"
}

lo=0
hi=20
while [ $(expr $hi - $lo) -ne 1 ]; do
  mid=$(expr '(' $hi + $lo ')' / 2)
  echo $lo $hi $mid

	cp -rf backup/* /root/.secretd/
	$SECRETD start > log 2>&1 &
    
    sleep $sleep_time
    while true; do
        sleep $sleep_time
        if [ $((start_secretd)) -eq 0 ]; then break; fi
    done

    txhash1={$($SECRETD tx compute execute $CONTRACT "{\"transfer\":{\"recipient\":\"$SENDER\", \"amount\": \"$mid\", \"memo\":\"\"}}" --from $ADV -y | jq .txhash):1:64}

    sleep $sleep_time
    while true; do
        sleep $sleep_time
        if [ $((query_tx_res $txhash1)) -eq 0 ]; then break; fi
    done
    res1=$($SECRETD q tx $txhash1 | jq .code)

    txhash2=$($SECRETD tx compute execute $CONTRACT "{\"transfer\":{\"recipient\":\"$RECEIVER\", \"amount\": \"$AMOUNT\", \"memo\":\"\"}}" --from $SENDER -y | jq .txhash)
    
    sleep $sleep_time
    tx2_done=$(query_tx_res ${txhash2:1:64})
    while [ "$tx2_done" -ne "0" ]; do
        sleep $sleep_time
        tx2_done=$(query_tx_res ${txhash2:1:64})
    done
    res2=$($SECRETD q tx ${txhash2:1:64} | jq .code)

    pkill -f $SECRETD

  echo $res1 $res2

  if [ $dif_pool_a -gt 0 ]; then lo=$mid; else hi=$mid; fi
done
echo $lo



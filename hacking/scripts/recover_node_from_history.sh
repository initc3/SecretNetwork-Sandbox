set -e
set -x

ADV='secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne'

sleep_time=1
cnt_max=5

start_secretd() {
    dev=$(secretd q account $ADV)
    echo "$?"
}

pkill -f secretd || true
sleep 2

#curr_dir=$(pwd)
#cd /go/src/github.com/enigmampc/SecretNetwork/
#make build_local_no_rust
#cp secretd /usr/bin/secretd
#chmod +x secretd
#cd $curr_dir

cp -rf ./hist_data /root/.secretd/data/

RUST_BACKTRACE=1 secretd start --rpc.laddr tcp://0.0.0.0:26657 > log 2>&1 &

cnt=0
while true; do
    ((cnt=cnt+1))
  sleep $sleep_time
    if [ $(start_secretd) == 0 ]; then break; fi
    if [ $((cnt%cnt_max)) == 0 ]; then (RUST_BACKTRACE=1 secretd start --rpc.laddr tcp://0.0.0.0:26657 > log 2>&1 &); fi
done
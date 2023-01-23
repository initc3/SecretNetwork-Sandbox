
# Steps

### Install tests

`npm install`

### Build simple contract

`make`

### Build Secret Network Node image

`./build_image.sh`

### Start One node network

`./start_node.sh`


### Rebuild 

Rebuild `go-cosmwasm/src` and `x/` and restart node (after `./start_node.sh` was run)

* From outside docker container

`./rebuild_node.sh`

* From inside docker container

```bash
docker-compose exec localsecret-2 bash
$ ./scripts/rebuild.sh &> /root/out &
$ cat out
```


### Tests

* Test simple functionality of dummy_store

`./test_dummy_store.sh`


* Deploy & instantiate new contract

`./node_modules/.bin/jest -t Setup`

* Query value stored in contract and check if it is the initial value instatiated in the contract
  
`./node_modules/.bin/jest -t QueryOld`

* Update value stored in contract
  
`./node_modules/.bin/jest -t Update`

* Query value stored in contract and check if it is the update value 

`./node_modules/.bin/jest -t QueryNew`


### Cleanup

* remove container volumes

```bash
sudo rm -rf secretd-1
sudo rm -rf secretd-2
```

* shutdown containers

`docker-compose down`

* delete network

`docker network rm hacking_default`

### Keeper
[keeper.go](../x/compute/internal/keeper/keeper.go#L478)

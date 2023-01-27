
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
* Test simple functionality of delivertx

`docker-compose exec localsecret-2 ./scripts/test_delivertx.sh`

* Test simple functionality of dummy_store

typescript verion:

`./test_dummy_store.sh`

secretd version:

`docker-compose exec localsecret-2 ./scripts/test_dummy_store_cli.sh`

#### IntegrationTests in test.ts

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

### Other
#### Update protobuf for rpc calls

* Update proto spec and other relevant files

    * [msg.proto](../proto/secret/compute/v1beta1/msg.proto)
    * [alias.go](../x/compute/alias.go)
    * [cli/tx.go](x/compute/client/cli/tx.go)
    * [rest/tx.go](x/compute/client/rest/tx.go)
    * [handler.go](x/compute/handler.go)
    * [msg_server.go](x/compute/internal/keeper/msg_server.go)
    * [codec.go](x/compute/internal/types/codec.go)
    * [msg.go](x/compute/internal/types/msg.go)

* generate protobuf files `make proto-gen`

    * you can ignore errors: `W0123 19:43:24.908481     375 services.go:38] No HttpRule found for method: Msg....` 

* build image `./build_image.sh` or `./rebuild_node.sh`

#### Keeper
[keeper.go](../x/compute/internal/keeper/keeper.go#L478)

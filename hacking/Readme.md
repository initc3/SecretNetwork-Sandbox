
# Steps

### Install tests

`npm install`

### Build simple contract

`make`

### Start One node network

Just start node

`./start_node.sh`

or start node network and try rollback

`./rollback.sh`


remove container volumes

```
sudo rm -rf secretd-1
sudo rm -rf secretd-2
```

### Keeper
[keeper.go](../x/compute/internal/keeper/keeper.go#L478)

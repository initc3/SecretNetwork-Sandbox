## SNIP-20 privacy hack
Under the `hacking` directory, build node with no victim balance key specified and start with
```
sudo ./start_node.sh
```
Then deploy contract
```
./node_modules/.bin/jest -t Setup
```

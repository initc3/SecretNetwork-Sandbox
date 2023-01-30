## SNIP-20 privacy hack
```
docker-compose down
docker system prune

./build_image.sh

sudo ./start_node.sh

./node_modules/.bin/jest -t Setup
sudo rm -rf backup
mkdir backup
sudo cp -r secretd-2/* backup/

sudo vim backup/victim_key
sudo ./restart_node.sh
```

Copy the backup folder to secretd-2 everytime restart the node



victim_key: 
317976d9fb06312ffc915651efc3c66f679e7b7c0e19ef4043b5c660f0cc8526
codeHash: 
22e8cdd3fddb5d25dfbb4e90dd904b6068297ab58ed45cfdda51552b18f9e854
contractAddress: 
secret18vd8fpwxzck93qlwghaj6arh4p7c5n8978vsyg


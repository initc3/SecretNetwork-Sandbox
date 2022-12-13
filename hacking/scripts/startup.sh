#!/bin/bash
echo "SECRET_NODE_TYPE {$SECRET_NODE_TYPE} node"

if [ "$SECRET_NODE_TYPE" == "NODE" ]
then
  echo "startup {NODE} node"
  file=/root/.secretd/config/started.txt
  if [ ! -e "$file" ]
  then
    ./scripts/node_init.sh
  else
    ./scripts/node_init.sh &> /root/out
    sleep infinity
  fi

else
  echo "startup {BOOTSTRAP} node"
  ./scripts/bootstrap_init.sh
fi

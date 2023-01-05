#!/bin/bash
echo "SECRET_NODE_TYPE {$SECRET_NODE_TYPE} node"

if [ "$SECRET_NODE_TYPE" == "NODE" ]
then
  echo "startup {NODE} node"
  file=/root/.secretd/config/started.txt
  if [ ! -e "$file" ]
  then
    ./node_init.sh
  else
    ./node_init.sh
    sleep infinity
  fi

else
  echo "startup {BOOTSTRAP} node"
    ./bootstrap_init.sh
fi

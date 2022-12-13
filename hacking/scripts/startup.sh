#!/bin/bash
echo "SECRET_NODE_TYPE {$SECRET_NODE_TYPE} node"

if [ "$SECRET_NODE_TYPE" == "NODE" ]
then
  echo "startup {NODE} node"
    ./node_init.sh
else
  echo "startup {BOOTSTRAP} node"
    ./bootstrap_init.sh
fi

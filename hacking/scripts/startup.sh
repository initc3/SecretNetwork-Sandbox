#!/bin/bash
echo "SECRET_NODE_TYPE {$SECRET_NODE_TYPE} node"

if [ "$SECRET_NODE_TYPE" == "NODE" ]
then
  echo "startup {NODE} node"
  ./scripts/node_init.sh
  sleep infinity
else
  echo "startup {BOOTSTRAP} node"
  ./scripts/bootstrap_init.sh
fi

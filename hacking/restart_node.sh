#!/bin/bash

docker-compose restart localsecret-2
sleep 10
docker-compose logs localsecret-2 --tail 100
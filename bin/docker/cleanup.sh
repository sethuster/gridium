#!/bin/bash

#do normal docker cleanup
docker rm -fv $(docker ps -qa)

#purge any gridium images so docker-compose up will rebuild it
docker rmi $(docker images gridium_gridium --format "{{.ID}}")

#and another hack to revert the dockerfile
git checkout ./Dockerfile
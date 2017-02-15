#!/bin/bash

docker-compose up

#now shell into gridium container and execute tests you want to see run
# docker exec gridium_gridium_1 rspec /spec/element_spec.rb -e "text input"
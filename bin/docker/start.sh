#!/bin/bash

#stomp dockerfile with our s3 credentials. alternately set s3 screenshots to false
sed -i -e "s/{{S3_ACCESS_KEY_ID}}/$S3_ACCESS_KEY_ID/" ./Dockerfile;
sed -i -e "s/{{S3_SECRET_ACCESS_KEY}}/$S3_SECRET_ACCESS_KEY/" ./Dockerfile;
sed -i -e "s/{{S3_DEFAULT_REGION}}/$S3_DEFAULT_REGION/" ./Dockerfile;
sed -i -e "s/{{S3_ROOT_BUCKET}}/$S3_ROOT_BUCKET/" ./Dockerfile;

docker-compose up

#now shell into gridium container and execute tests you want to see run
# docker exec gridium_gridium_1 rspec /spec/element_spec.rb -e "disabled"
#!/bin/bash

./docker_build.sh

# Run the server
docker run -p 26910:26910 -p 26910:26910/udp -p 26911:26911/udp -p 26912:26912/udp -p 26913:26913/udp -p 8082:8080 -p 8083:8081 -e SEVEN_DAYS_TO_DIE_UPDATE_CHECKING="1" -v $(pwd)/7dtd_data:/steamcmd/7dtd --name 7dtd-server -t didstopia/7dtd-server:latest

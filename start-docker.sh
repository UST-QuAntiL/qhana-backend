#!/bin/sh

# copy config and qhana db into volume
cp -n /app/Config.toml /app/qhana-backend.db /app/data/

# wait for db to start
/app/wait

# set working directory manually
cd /app/data

# start backend
java -jar /app/qhana_backend.jar

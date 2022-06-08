#!/bin/sh

# copy config and qhana db into volume
eval "echo \"$(cat /app/liquibase.properties)\"" > /app/liquibase.properties
cp -n /app/Config.toml /app/qhana-backend.db /app/liquibase.properties /app/changelog-mariadb.sql /app/data/


# wait for db to start
/app/wait

# set working directory manually
cd /app/data

# update database
liquibase update

# start backend
java -jar /app/qhana_backend.jar

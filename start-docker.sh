#!/bin/sh

# prepare sqlite database
cp /app/liquibase.properties /app/data/liquibase.properties
liquibase --url=jdbc:sqlite:qhana-backend.db --classpath=../liquibase/internal/lib/sqlite-jdbc.jar --driver=org.sqlite.JDBC --changelog-file=../changelog.xml updateTestingRollback

# insert env var for mariadb liquibase config
eval "echo \"$(cat /app/liquibase.mariadb.properties)\"" > /app/data/liquibase.properties

# copy config and qhana db into volume
cp /app/Config.toml /app/changelog.xml /app/data/


# wait for db to start
/app/wait

# set working directory manually
cd /app/data

# update mariadb database
liquibase updateTestingRollback

# start backend
java -jar /app/qhana_backend.jar

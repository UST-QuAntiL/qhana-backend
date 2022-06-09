#!/bin/sh

# prepare sqlite database
liquibase --url=jdbc:sqlite:qhana-backend.db --classpath=../liquibase/internal/lib/sqlite-jdbc.jar --driver=org.sqlite.JDBC --changelog-file=../changelog-sqlite.sql updateTestingRollback

# insert env var for mariadb liquibase config
eval "echo \"$(cat /app/liquibase.properties)\"" > /app/liquibase.properties

# copy config and qhana db into volume
cp -n /app/Config.toml /app/liquibase.properties /app/changelog-mariadb.sql /app/data/


# wait for db to start
/app/wait

# set working directory manually
cd /app/data

# update mariadb database
liquibase updateTestingRollback

# start backend
java -jar /app/qhana_backend.jar

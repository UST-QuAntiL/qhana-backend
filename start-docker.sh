#!/bin/sh

# prepare sqlite database
cp /app/liquibase.properties /app/data/liquibase.properties
liquibase --url=jdbc:sqlite:qhana-backend.db --classpath=../liquibase/internal/lib/sqlite-jdbc.jar --driver=org.sqlite.JDBC --changelog-file=../changelog.xml updateTestingRollback

# insert env var for mariadb liquibase config
cat << EOF > /app/data/liquibase.properties
classpath: ../liquibase/internal/lib/mariadb-java-client.jar
url: jdbc:$QHANA_DB_TYPE://$QHANA_DB_HOST/$QHANA_DB_NAME
changelog-file: ../changelog.xml
username: $QHANA_DB_USER
password: $QHANA_DB_PASSWORD

liquibase.secureParsing=false
liquibase.hub.mode=off
EOF

# copy config and qhana db into volume
cp -n /app/Config.toml /app/data/


# wait for db to start
/app/wait

# set working directory manually
cd /app/data

# update mariadb database
liquibase updateTestingRollback

# start backend
java -jar /app/qhana_backend.jar

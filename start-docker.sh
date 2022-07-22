#!/bin/sh

# prepare sqlite database
liquibase --url=jdbc:sqlite:qhana-backend.db --classpath=/app --driver=org.sqlite.JDBC --changelog-file=changelog.xml --secure-parsing=false --hub-mode=off updateTestingRollback

# insert env var for mariadb liquibase config
cat << EOF > /app/liquibase.properties
classpath: /app
url: jdbc:$QHANA_DB_TYPE://$QHANA_DB_HOST/$QHANA_DB_NAME
changelog-file: changelog.xml
username: $QHANA_DB_USER
password: $QHANA_DB_PASSWORD

liquibase.secureParsing=false
liquibase.hub.mode=off
EOF

# copy config and qhana db into volume
cp -n /app/Config.toml /app/qhana-backend.db /app/data/

# wait for db to start
/app/wait

# update mariadb database
cd /app
liquibase updateTestingRollback

# set working directory manually
cd /app/data

# start backend
java -jar /app/qhana_backend.jar

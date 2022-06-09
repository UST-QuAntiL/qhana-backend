#!/bin/bash

# get sqlite driver for liquibase
JDBC=lib/sqlite-jdbc-3.36.0.3.jar
if [ ! -f "$JDBC" ]; then
    wget -P lib https://github.com/xerial/sqlite-jdbc/releases/download/3.36.0.3/sqlite-jdbc-3.36.0.3.jar
fi

# set up db or deploy db changes
if ! command -v liquibase; then
    echo "Liquibase not found. Are you sure that you have installed it? For more information, visit https://www.liquibase.org/download"
    exit
fi
liquibase updateTestingRollback

FROM eclipse-temurin:11 AS builder

RUN apt-get -y update && apt-get install unzip

WORKDIR /app

# install ballerina
RUN wget https://dist.ballerina.io/downloads/swan-lake-beta3/ballerina-swan-lake-beta3.zip
RUN unzip ballerina-swan-lake-beta3.zip
ENV PATH="${PATH}:/app/ballerina-swan-lake-beta3/bin"

# install liquibase
RUN wget https://github.com/liquibase/liquibase/releases/download/v4.11.0/liquibase-4.11.0.zip
RUN unzip liquibase-4.11.0.zip -d /app/liquibase

# copy files
COPY . /app

RUN bal build --observability-included --skip-tests

FROM openjdk:11-jre-slim

LABEL org.opencontainers.image.source="https://github.com/UST-QuAntiL/qhana-backend"

RUN apt-get -y update && apt-get install -y sqlite3

# create unpriviledged user
RUN useradd ballerina

# create persistent data volume and change its owner to the new user
VOLUME /app/data
RUN mkdir --parents /app/data && chown --recursive ballerina /app

WORKDIR /app/data

COPY --from=builder --chown=ballerina /app/target/bin/qhana_backend.jar /app/

COPY --from=builder --chown=ballerina /app/liquibase /app/liquibase
COPY --chown=ballerina changelog.xml /app/

COPY --chown=ballerina start-docker.sh /app/

EXPOSE 9090

# Wait for database
ADD --chown=ballerina https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait /app/wait

# make scripts executable
RUN chmod +x /app/wait && chmod +x /app/start-docker.sh

# switch to unpriviledged user
USER ballerina

# enable liquibase
ENV PATH="${PATH}:/app/liquibase"

# run backend
CMD /app/start-docker.sh


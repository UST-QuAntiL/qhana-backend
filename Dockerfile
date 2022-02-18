FROM openjdk:11 AS builder

WORKDIR /app

# install ballerina
RUN wget https://dist.ballerina.io/downloads/swan-lake-beta3/ballerina-swan-lake-beta3.zip
RUN unzip ballerina-swan-lake-beta3.zip
ENV PATH="${PATH}:/app/ballerina-swan-lake-beta3/bin"

# copy files
COPY . /app

RUN bal build --observability-included --skip-tests



FROM openjdk:11

LABEL org.opencontainers.image.source="hhttps://github.com/UST-QuAntiL/qhana-backend"

RUN apt-get -y update && apt-get install -y sqlite3

# create unpriviledged user
RUN useradd ballerina

# create persistent data volume and change its owner to the new user
VOLUME /app/data
RUN mkdir --parents /app/data && chown --recursive ballerina /app

WORKDIR /app/data

COPY --from=builder --chown=ballerina /app/target/bin/qhana_backend.jar /app/

COPY --chown=ballerina sqlite-schema.sql start-docker.sh /app/

# Apply docker specific config
COPY --chown=ballerina Config-docker.toml /app/Config.toml

EXPOSE 9090

# Wait for database
ADD --chown=ballerina https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait /app/wait

# make scripts executable
RUN chmod +x /app/wait && chmod +x /app/start-docker.sh

# switch to unpriviledged user
USER ballerina

# prepare database
RUN sqlite3 /app/qhana-backend.db < /app/sqlite-schema.sql

# run backend
CMD /app/start-docker.sh

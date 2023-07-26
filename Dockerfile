FROM eclipse-temurin:11 AS builder

RUN apt-get -y update && apt-get install unzip
WORKDIR /app

# install ballerina
ARG BAL_VERSION="2201.7.0-swan-lake"
RUN wget --no-verbose https://dist.ballerina.io/downloads/2201.7.0/ballerina-${BAL_VERSION}.zip
RUN unzip ballerina-${BAL_VERSION}
ENV PATH="${PATH}:/app/ballerina-${BAL_VERSION}/bin"

# install liquibase
RUN wget --no-verbose https://github.com/liquibase/liquibase/releases/download/v4.11.0/liquibase-4.11.0.zip
RUN unzip liquibase-4.11.0.zip -d /app/liquibase

# copy files
COPY . /app

RUN bal build --observability-included

FROM eclipse-temurin:11-jre

LABEL org.opencontainers.image.source="https://github.com/UST-QuAntiL/qhana-backend"

RUN apt-get -y update && apt-get install -y sqlite3 unzip zip

WORKDIR /app

# install proxy
ADD https://raw.githubusercontent.com/UST-QuAntiL/docker-localhost-proxy/v0.3/install_proxy.sh install_proxy.sh
RUN chmod +x install_proxy.sh && ./install_proxy.sh

# add localhost proxy files
ADD --chown=ballerina https://raw.githubusercontent.com/UST-QuAntiL/docker-localhost-proxy/v0.3/Caddyfile.template Caddyfile.template
ADD --chown=ballerina https://raw.githubusercontent.com/UST-QuAntiL/docker-localhost-proxy/v0.3/start_proxy.sh start_proxy.sh
RUN chmod +x start_proxy.sh

# create unpriviledged user
RUN useradd ballerina

# create persistent data volume and change its owner to the new user
RUN mkdir --parents /app/data && chown --recursive ballerina /app
VOLUME /app/data

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
CMD (cd /app && ./start_proxy.sh) && /app/start-docker.sh

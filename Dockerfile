FROM ubuntu:focal
WORKDIR /app
RUN apt-get -y update && apt-get install -y wget sqlite3 unzip apt-transport-https gnupg

# install adoptopenjdk 11
RUN wget https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
RUN gpg --no-default-keyring --keyring ./adoptopenjdk-keyring.gpg --import public
RUN gpg --no-default-keyring --keyring ./adoptopenjdk-keyring.gpg --export --output adoptopenjdk-archive-keyring.gpg
RUN rm adoptopenjdk-keyring.gpg
RUN mv adoptopenjdk-archive-keyring.gpg /usr/share/keyrings
RUN echo "deb [signed-by=/usr/share/keyrings/adoptopenjdk-archive-keyring.gpg] https://adoptopenjdk.jfrog.io/adoptopenjdk/deb focal main" | tee /etc/apt/sources.list.d/adoptopenjdk.list
RUN apt-get -y update && apt-get install -y adoptopenjdk-11-hotspot

# rename the installation folder so that the folder name is the same on every architecture
RUN ln -s /usr/lib/jvm/adoptopenjdk-11-hotspot* /usr/lib/jvm/java-11
ENV JAVA_HOME="/usr/lib/jvm/java-11"

# install ballerina
RUN wget https://dist.ballerina.io/downloads/swan-lake-beta2/ballerina-swan-lake-beta2.zip
RUN unzip ballerina-swan-lake-beta2.zip
ENV PATH="${PATH}:/app/ballerina-swan-lake-beta2/bin"

# copy files
COPY . /app

# prepare database
RUN bash create-sqlite-db.sh

# run backend
CMD bal run

# Based upon https://github.com/cnadiminti/docker-dynamodb-local/blob/master/Dockerfile
# FROM openjdk:8-jre-alpine
FROM frolvlad/alpine-oraclejdk8

RUN apk update && apk add --no-cache curl py2-pip groff less && \
  pip install awscli && \
  mkdir /var/dynamodb && \
  mkdir /dynamodb

WORKDIR /var/dynamodb

ENV DYNAMODB_VERSION=latest
ENV JAVA_OPTS=
ENV AWS_ACCESS_KEY_ID=123
ENV AWS_SECRET_ACCESS_KEY=123
ENV AWS_DEFAULT_REGION=none

RUN curl -O https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_${DYNAMODB_VERSION}.tar.gz && \
    tar zxvf dynamodb_local_${DYNAMODB_VERSION}.tar.gz && \
    rm dynamodb_local_${DYNAMODB_VERSION}.tar.gz

COPY ./entrypoint.sh /
COPY ./build/data/shared-local-instance.db /dynamodb
COPY ./build/truncated_data.json /dynamodb/imported_data.json

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8000

CMD ["--sharedDb", "-dbPath", "/dynamodb", "-port", "8000"]

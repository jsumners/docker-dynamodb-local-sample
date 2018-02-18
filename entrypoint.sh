#!/bin/sh
set -e
exec java -Djava.library.path=. ${JAVA_OPTS} -jar DynamoDBLocal.jar "$@"

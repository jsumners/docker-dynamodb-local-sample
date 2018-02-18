#!/bin/bash

AWS=$(which aws)
if [ ! $? -eq 0 ]; then
  echo "Must have awscli installed: pip install awscli"
  exit 1
fi

JAVA=$(which java)
if [ ! $? -eq 0 ]; then
  echo "Must have Java installed"
  exit 1
fi

JQ=$(which jq)
if [ ! $? -eq 0 ]; then
  echo "Must have jq installed: https://stedolan.github.io/jq/"
  exit 1
fi

JO=$(which jo)
if [ ! $? -eq 0 ]; then
  echo "Must have jo installed: https://github.com/jpmens/jo"
  exit 1
fi

mkdir -p build/data
cd build

curl -O https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_${DYNAMODB_VERSION:=latest}.tar.gz
tar zxf dynamodb_local_${DYNAMODB_VERSION}.tar.gz
rm dynamodb_local_${DYNAMODB_VERSION}.tar.gz

curl -O https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/samples/moviedata.zip
unzip -o moviedata.zip
rm moviedata.zip

${JAVA} -Djava.library.path=. -jar DynamoDBLocal.jar --sharedDb -dbPath ./data -port 8000 1>/dev/null 2>&1 &
JAVA_PID=$!
if [ ! $? -eq 0 ]; then
  echo "Failed to start DynamoDB. Aborting"
  exit 1
fi
sleep 1

if [ ! -e ./data/shared-local-instance.db ]; then
  touch ./data/shared-local-instance.db
fi

DB_SIZE=$(du ./data/shared-local-instance.db | awk '{print $1}')
if [ ${DB_SIZE} -lt 500 ]; then
  export AWS_ACCESS_KEY_ID=123
  export AWS_SECRET_ACCESS_KEY=123
  export AWS_DEFAULT_REGION=none

  aws dynamodb create-table \
    --endpoint-url http://0.0.0.0:8000 \
    --table-name Movies \
    --attribute-definitions \
      AttributeName=year,AttributeType=N \
      AttributeName=title,AttributeType=S \
    --key-schema \
      AttributeName=year,KeyType=HASH \
      AttributeName=title,KeyType=RANGE \
    --provisioned-throughput \
      ReadCapacityUnits=10,WriteCapacityUnits=5
  if [ ! $? -eq 0 ]; then
    kill ${JAVA_PID}
    echo "Could not create table. Aborting"
    exit 1
  fi

  cat moviedata.json | jq '[limit(1024; .[])]' > truncated_data.json
  echo "Importing sample data. This will take a while ..."
  #declare -a MOVIES
  while IFS= read -r; do
    YEAR=$(echo "${REPLY}" | ${JQ} -r '.year')
    TITLE=$(echo "${REPLY}" | ${JQ} -r '.title')
    ${JO} -p -- -s year[N]="${YEAR}" title[S]="${TITLE}" > item.json
    ${AWS} dynamodb put-item \
      --endpoint-url http://0.0.0.0:8000 \
      --table-name Movies \
      --item file://item.json
  #  MOVIES+=("${REPLY}")
  done < <(cat truncated_data.json | ${JQ} -r -c '.[]')
fi

kill ${JAVA_PID}

cd ..
docker build -t jsumners/dynamodb-local-sample .

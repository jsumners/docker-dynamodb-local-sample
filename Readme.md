# dynamodb-local-sample

Provides an instance of [DynamoDB][ddb] with a subset of the [sample movie data][sample].
It includes:

+ `awscli` installed
+ `/dynamodb/imported_data.json` to show what is available

## Run It

```sh
$ docker run --rm -it -p 8000:8000 jsumners/dynamodb-local-sample
```

To navigate the filesystem:

```sh
$ docker run --rm -it --entrypoint /bin/sh jsumners/dynamodb-local-sample
```

[ddb]: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html
[sample]: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.NodeJs.02.html

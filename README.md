# docker-elastalert

Docker image for running Travix's Elastalert infrastructure

## Features

* Docker container that conforms to [The Twelve-Factor App Section III](https://12factor.net/config) configuration guidelines by making everything available using environment variables.
* NTP syncrhonization
* OpsGenie integration
* Rules processing using one Docker base image

## Local Development Usage

Locally the `docker-elastalert` instance can be run using any one of the following commands:

```
make localup
docker-compose up -d --build
```

The local cluster spins up a dummy Elasticsearch container, and then the Elastalert container. When the Elastalert container starts, the `CMD` script runs through the following processes:

* Sets container timezone to `${CONTAINER_TIMEZONE}` if the `${SET_CONTAINER_TIMEZONE}` is set to `True`. The default is `Europe/Amsterdam`.
* Starts the NTP daemon for time synchronization. This requires the following Linux capabilities set via `cap_add`: `SYS_NICE` and `SYS_TIME`.
* Populates the Elastalert template located at `${CONFIG_DIR}/elastalert_config.yaml.tmpl` with environment variables using the `dockerize` binary ([Dockerize Project](https://github.com/jwilder/dockerize)).
* Changes some defaults about the Elastalert supervisord configuration.
* Loops a `wget` command until the Elasticsearch instance located at `${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}` becomes available.
* Runs `elastalert-create-index` if the specified `${ELASTALERT_INDEX}` hasn't yet been created,
* Executes `supervisord`.

## Production Usage

<Later>

## Required Environment Variables

The following environment variables have no defaults, and **need** to be set.

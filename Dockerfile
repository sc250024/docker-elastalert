FROM alpine:3.6

LABEL maintainer="Scott Crooks <scott.crooks@gmail.com>"

# Set configuration parameters needed for the image and container configuration
## CONFIG_FOLDER => Directory holding configuration for Elastalert.
## CONTAINER_TIMEZONE => Default container timezone as found under the directory /usr/share/zoneinfo/.
## DOCKERIZE_VERSION => Version of `dockerize` binary to download.
## DUMBINIT_VERSION => Specify the `dumb-init` version to use for starting the Python process; more info here: https://github.com/Yelp/dumb-init
## RULES_FOLDER => Elastalert rules directory.
## SET_CONTAINER_TIMEZONE => Set this environment variable to True to set timezone on container start.

ENV CONFIG_FOLDER=/opt/elastalert/config \
    CONTAINER_TIMEZONE=Etc/UTC \
    DOCKERIZE_VERSION=0.5.0 \
    DUMBINIT_VERSION=1.2.0 \
    RULES_FOLDER=/opt/elastalert/rules \
    SET_CONTAINER_TIMEZONE=True

# Set parameters needed for the `src/start-elastalert` script
## ELASTALERT_CONFIG => Location of the Elastalert configuration file based on the ${CONFIG_FOLDER}
## ELASTALERT_INDEX => ElastAlert writeback index
## ELASTICSEARCH_HOST => Alias, DNS or IP of Elasticsearch host to be queried by Elastalert. Set in default Elasticsearch configuration file.
## ELASTICSEARCH_PORT => Port on above Elasticsearch host. Set in default Elasticsearch configuration file.
## ELASTICSEARCH_USE_SSL => Use TLS to connect to Elasticsearch (True or False)
## ELASTICSEARCH_VERIFY_CERTS => Verify TLS

ENV ELASTALERT_CONFIG="${CONFIG_FOLDER}/elastalert_config.yaml" \
    ELASTALERT_INDEX=elastalert_status \
    ELASTALERT_VERSION=0.1.21 \
    ELASTICSEARCH_HOST=elasticsearch \
    ELASTICSEARCH_PORT=9200 \
    ELASTICSEARCH_USE_SSL=False \
    ELASTICSEARCH_VERIFY_CERTS=False

# Install packages
RUN set -ex \
    && apk update \
    && apk upgrade \
    && apk add --no-cache \
        ca-certificates \
        openntpd \
        openssl \
        py2-pip \
        py2-yaml \
        python2 \
        tzdata \
        wget \
    && apk add --no-cache --virtual \
        .build-dependencies \
        gcc \
        libffi-dev \
        musl-dev \
        openssl-dev \
        python2-dev \
    && pip install dumb-init=="${DUMBINIT_VERSION}" \
    && pip install elastalert=="${ELASTALERT_VERSION}" \
    && apk del .build-dependencies \
    && rm -rf /var/cache/apk/*

# Get Dockerize for configuration templating
RUN set -ex \
    && wget -nv -O dockerize.tar.gz \
        "https://github.com/jwilder/dockerize/releases/download/v${DOCKERIZE_VERSION}/dockerize-alpine-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz" \
    && tar -C /usr/local/bin -xzvf dockerize.tar.gz \
    && chmod +x "/usr/local/bin/dockerize" \
    && rm dockerize.tar.gz

# Create directories. The /var/empty directory is used by openntpd.
RUN mkdir -p "${CONFIG_FOLDER}" \
    && mkdir -p "${RULES_FOLDER}" \
    && mkdir -p /var/empty

# Copy the ${ELASTALERT_CONFIG} template
COPY src/elastalert_config.yaml.tmpl "${CONFIG_FOLDER}/elastalert_config.yaml.tmpl"

# Copy the script used to launch the Elastalert when a container is started.
COPY src/start-elastalert /opt/elastalert/

# Make the start-script executable.
RUN chmod +x /opt/elastalert/start-elastalert

# The square brackets around the 'e' are intentional. They prevent `grep`
# itself from showing up in the process list and falsifying the results.
# See here: https://stackoverflow.com/questions/9375711/more-elegant-ps-aux-grep-v-grep
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD ps -ef | grep "[e]lastalert.elastalert" >/dev/null 2>&1

# Runs "/usr/bin/dumb-init -- /my/script --with --args"
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Launch Elastalert when a container is started.
CMD ["/opt/elastalert/start-elastalert"]

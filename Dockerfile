FROM alpine:3.6

LABEL maintainer="Scott Crooks <scrooks@travix.com>"

## Set base Elastalert version
# ELASTALERT_VERSION => Version of ElastAlert to download.
ENV ELASTALERT_VERSION 0.1.20

## Set configuration parameters needed for the image and container configuration
# APP_FOLDER => Specify the extract location and home directory of the Elastalert application.
# APP_DOWNLOAD_URL => URL from which to download Elastalert.
# CONFIG_FOLDER => Directory holding configuration for Elastalert.
# CONTAINER_TIMEZONE => Default container timezone as found under the directory /usr/share/zoneinfo/.
# DOCKERIZE_VERSION => Version of `dockerize` binary to download.
# DUMBINIT_VERSION => Specify the `dumb-init` version to use for starting the Python process; more info here: https://github.com/Yelp/dumb-init
# LOG_FOLDER => Directory to which Elastalert logs are written.
# RULES_FOLDER => Elastalert rules directory.
# SET_CONTAINER_TIMEZONE => Set this environment variable to True to set timezone on container start.

ENV APP_FOLDER=/opt/elastalert \
    APP_DOWNLOAD_URL=https://github.com/Yelp/elastalert/archive/v${ELASTALERT_VERSION}.tar.gz \
    CONFIG_FOLDER=/opt/config \
    CONTAINER_TIMEZONE=Etc/UTC \
    DOCKERIZE_VERSION=0.5.0 \
    DUMBINIT_VERSION=1.2.0 \
    LOG_FOLDER=/opt/logs \
    RULES_FOLDER=/opt/rules \
    SET_CONTAINER_TIMEZONE=False

## Set parameters needed for the `src/start-elastalert.sh` script
# ELASTALERT_CONFIG => Location of the Elastalert configuration file based on the ${CONFIG_FOLDER}
# ELASTALERT_INDEX => ElastAlert writeback index
# ELASTICSEARCH_HOST => Alias, DNS or IP of Elasticsearch host to be queried by Elastalert. Set in default Elasticsearch configuration file.
# ELASTICSEARCH_PORT => Port on above Elasticsearch host. Set in default Elasticsearch configuration file.
# ELASTICSEARCH_USE_SSL => Use TLS to connect to Elasticsearch (True or False)
# ELASTICSEARCH_VERIFY_CERTS => Verify TLS

ENV ELASTALERT_CONFIG="${CONFIG_FOLDER}"/elastalert_config.yaml \
    ELASTALERT_INDEX=elastalert_status \
    ELASTICSEARCH_HOST=elasticsearch \
    ELASTICSEARCH_PORT=9200 \
    ELASTICSEARCH_USE_SSL=False \
    ELASTICSEARCH_VERIFY_CERTS=False

WORKDIR /opt

# Install software required for Elastalert and NTP for time synchronization.
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        ca-certificates \
        gcc \
        libffi-dev \
        musl-dev \
        openntpd \
        openssl \
        openssl-dev \
        py2-pip \
        py2-yaml \
        python2 \
        python2-dev \
        tzdata \
        wget \
    && wget -O elastalert.tar.gz "${APP_DOWNLOAD_URL}" \
    && tar -xvzf elastalert.tar.gz \
    && rm elastalert.tar.gz \
    && mv elastalert-* "${APP_FOLDER}" \
    && cd "${APP_FOLDER}" \
    && pip install --upgrade pip \
    && python setup.py install \
    && pip install -e . \
    && pip install dumb-init=="${DUMBINIT_VERSION}" \
    && apk del \
        gcc \
        libffi-dev \
        musl-dev \
        openssl-dev \
        python2-dev \
    && rm -rf /var/cache/apk/*

RUN wget -O dockerize.tar.gz \
        https://github.com/jwilder/dockerize/releases/download/"${DOCKERIZE_VERSION}"/dockerize-alpine-linux-amd64-v"${DOCKERIZE_VERSION}".tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize.tar.gz \
    && rm dockerize.tar.gz

# Create directories. The /var/empty directory is used by openntpd.
RUN mkdir -p "${CONFIG_FOLDER}" \
    && mkdir -p "${RULES_FOLDER}" \
    && mkdir -p "${LOG_FOLDER}" \
    && mkdir -p /var/empty

# Copy the script used to launch the Elastalert when a container is started.
COPY src/start-elastalert.sh /opt/

# Copy the ${ELASTALERT_CONFIG} template
COPY src/config.yaml.tmpl "${CONFIG_FOLDER}/elastalert_config.yaml.tmpl"

# Make the start-script executable.
RUN chmod +x /opt/start-elastalert.sh

WORKDIR ${APP_FOLDER}

# The square brackets around the 'e' are intentional. They prevent `grep`
# itself from showing up in the process list and falsifying the results.
# See here: https://stackoverflow.com/questions/9375711/more-elegant-ps-aux-grep-v-grep
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD ps -ef | grep "[e]lastalert" >/dev/null 2>&1

# Runs "/usr/bin/dumb-init -- /my/script --with --args"
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Launch Elastalert when a container is started.
CMD ["/opt/start-elastalert.sh"]

FROM alpine:3.6

LABEL maintainer="Scott Crooks <scrooks@travix.com>"

# Set configuration parameters needed for the image and container configuration
## APP_DOWNLOAD_URL => URL from which to download Elastalert.
## APP_FOLDER => Specify the extract location and home directory of the Elastalert application.
## CONFD_VERSION => Version of `confd` binary to download.
## CONFIG_FOLDER => Directory holding configuration for Elastalert.
## CONTAINER_TIMEZONE => Default container timezone as found under the directory /usr/share/zoneinfo/.
## DUMBINIT_VERSION => Specify the `dumb-init` version to use for starting the Python process; more info here: https://github.com/Yelp/dumb-init
## LOG_FOLDER => Directory to which Elastalert logs are written.
## RULES_FOLDER => Elastalert rules directory.
## SET_CONTAINER_TIMEZONE => Set this environment variable to True to set timezone on container start.

ENV APP_FOLDER=/opt/elastalert \
    CONFD_VERSION=0.14.0 \
    CONFIG_FOLDER=/opt/config \
    CONTAINER_TIMEZONE=Etc/UTC \
    DUMBINIT_VERSION=1.2.0 \
    LOCAL_BIN=/usr/local/bin \
    LOG_FOLDER=/opt/logs \
    RULES_FOLDER=/opt/rules \
    SET_CONTAINER_TIMEZONE=False

# Set parameters needed for the `src/start-elastalert.sh` script
## ELASTALERT_CONFIG => Location of the Elastalert configuration file based on the ${CONFIG_FOLDER}
## ELASTALERT_INDEX => ElastAlert writeback index
## ELASTICSEARCH_HOST => Alias, DNS or IP of Elasticsearch host to be queried by Elastalert. Set in default Elasticsearch configuration file.
## ELASTICSEARCH_PORT => Port on above Elasticsearch host. Set in default Elasticsearch configuration file.
## ELASTICSEARCH_USE_SSL => Use TLS to connect to Elasticsearch (True or False)
## ELASTICSEARCH_VERIFY_CERTS => Verify TLS

ENV ELASTALERT_CONFIG="${CONFIG_FOLDER}/elastalert_config.yaml" \
    ELASTALERT_INDEX=elastalert_status \
    ELASTICSEARCH_HOST=elasticsearch \
    ELASTICSEARCH_PORT=9200 \
    ELASTICSEARCH_USE_SSL=False \
    ELASTICSEARCH_VERIFY_CERTS=False

# Set base Elastalert version
## ELASTALERT_VERSION => Version of ElastAlert to download.
ENV ELASTALERT_VERSION 0.1.21

# Install build time packages
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

# Get ConfD for configuration templating
RUN wget -nv -O "${LOCAL_BIN}/confd" \
        https://github.com/kelseyhightower/confd/releases/download/v"${CONFD_VERSION}"/confd-"${CONFD_VERSION}"-linux-amd64 \
    && chmod +x /usr/local/bin/confd

# Create directories. The /var/empty directory is used by openntpd.
RUN mkdir -p "${CONFIG_FOLDER}" \
    && mkdir -p "${RULES_FOLDER}" \
    && mkdir -p "${LOG_FOLDER}" \
    && mkdir -p /var/empty

# Copy the script used to launch the Elastalert when a container is started.
COPY src/start-elastalert.sh /opt/

# Copy the ${ELASTALERT_CONFIG} template
COPY src/elastalert_config.yaml.tmpl "${CONFIG_FOLDER}/elastalert_config.yaml.tmpl"

# Make the start-script executable.
RUN chmod +x /opt/start-elastalert.sh

# The square brackets around the 'e' are intentional. They prevent `grep`
# itself from showing up in the process list and falsifying the results.
# See here: https://stackoverflow.com/questions/9375711/more-elegant-ps-aux-grep-v-grep
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD ps -ef | grep "[e]lastalert.elastalert" >/dev/null 2>&1

# Runs "/usr/bin/dumb-init -- /my/script --with --args"
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Launch Elastalert when a container is started.
CMD ["/opt/start-elastalert.sh"]

FROM alpine:3.6

# CONFIG_DIR => Directory holding configuration for Elastalert and Supervisor.
# CONTAINER_TIMEZONE => Default container timezone as found under the directory /usr/share/zoneinfo/.
# DOCKERIZE_VERSION => Version of `dockerize` binary to download
# ELASTALERT_BUFFER_TIME => Time in minutes to run Elastalert; found under the 'buffer_time' setting
# ELASTALERT_CONFIG => Elastalert configuration file path in configuration directory.
# ELASTALERT_HOME => Elastalert home directory full path.
# ELASTALERT_INDEX => ElastAlert writeback index
# ELASTALERT_RUN_EVERY => How often to query Elasticsearch; found under the 'run_every' setting
# ELASTALERT_SUPERVISOR_CONF => Supervisor configuration file for Elastalert.
# ELASTALERT_TIME_LIMIT => Specify the retry window for failed alerts in minutes; found under the 'alert_time_limit' setting
# ELASTALERT_URL => URL from which to download Elastalert.
# ELASTALERT_VERSION => Version of ElastAlert to download
# ELASTICSEARCH_HOST => Alias, DNS or IP of Elasticsearch host to be queried by Elastalert. Set in default Elasticsearch configuration file.
# ELASTICSEARCH_PORT => Port on above Elasticsearch host. Set in default Elasticsearch configuration file.
# ELASTICSEARCH_TLS => Use TLS to connect to Elasticsearch (True or False)
# ELASTICSEARCH_TLS_VERIFY => Verify TLS
# LOG_DIR => Directory to which Elastalert and Supervisor logs are written.
# RULES_DIRECTORY => Elastalert rules directory.
# SET_CONTAINER_TIMEZONE => Set this environment variable to True to set timezone on container start.

ENV CONFIG_DIR=/opt/config \
    CONTAINER_TIMEZONE=Europe/Amsterdam \
    DOCKERIZE_VERSION=v0.5.0 \
    ELASTALERT_BUFFER_TIME=45 \
    ELASTALERT_HOME=/opt/elastalert \
    ELASTALERT_INDEX=elastalert_status \
    ELASTALERT_RUN_EVERY=3 \
    ELASTALERT_TIME_LIMIT=5 \
    ELASTALERT_VERSION=0.1.21 \
    ELASTICSEARCH_HOST=elasticsearch \
    ELASTICSEARCH_PORT=9200 \
    ELASTICSEARCH_TLS=False \
    ELASTICSEARCH_TLS_VERIFY=False \
    LOG_DIR=/opt/logs \
    RULES_DIRECTORY=/opt/rules \
    SET_CONTAINER_TIMEZONE=True

# Placing these rules here since they depend on the previous layer
ENV ELASTALERT_CONFIG=${CONFIG_DIR}/elastalert_config.yaml \
    ELASTALERT_SUPERVISOR_CONF=${CONFIG_DIR}/elastalert_supervisord.conf \
    ELASTALERT_URL=https://github.com/Yelp/elastalert/archive/v${ELASTALERT_VERSION}.tar.gz

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
    && wget -O elastalert.tar.gz "${ELASTALERT_URL}" \
    && tar -xvzf elastalert.tar.gz \
    && rm elastalert.tar.gz \
    && mv e* "${ELASTALERT_HOME}" \
    && cd "${ELASTALERT_HOME}" \
    && pip install --upgrade pip \
    && python setup.py install \
    && pip install -e . \
    && pip uninstall twilio --yes \
    && pip install twilio==6.0.0 \
    && easy_install supervisor \
    && apk del \
        gcc \
        libffi-dev \
        musl-dev \
        openssl-dev \
        python2-dev \
    && rm -rf /var/cache/apk/*

RUN wget -O dockerize.tar.gz \
        https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize.tar.gz \
    && rm dockerize.tar.gz

# Create directories. The /var/empty directory is used by openntpd.
RUN mkdir -p "${CONFIG_DIR}" \
    && mkdir -p "${RULES_DIRECTORY}" \
    && mkdir -p "${LOG_DIR}" \
    && mkdir -p /var/empty

# Copy the script used to launch the Elastalert when a container is started.
COPY src/start-elastalert.sh /opt/

# Copy the ${ELASTALERT_CONFIG} template
COPY src/config.yaml.tmpl "${CONFIG_DIR}/elastalert_config.yaml.tmpl"

# Make the start-script executable.
RUN chmod +x /opt/start-elastalert.sh

# # Launch Elastalert when a container is started.
CMD ["/opt/start-elastalert.sh"]

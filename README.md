# docker-elastalert

Docker image for running Elastalert.

## Features

* Docker container that conforms to [The Twelve-Factor App Section III](https://12factor.net/config) configuration guidelines by making everything available using environment variables.
* Integration with the following external services via environment variables:
  * E-mail (General SMTP)
  * Exotel
  * Gitter
  * HipChat
  * JIRA
  * OpsGenie
  * PagerDuty
  * Slack
  * Telegram
  * Twilio
  * VictorOps
* NTP syncrhonization
* Rules checking on container startup if `rules/` directory is populated

## Usage

Locally the `docker-elastalert` instance can be run using the following command:

```
docker-compose up -d --build
```

The local cluster spins up a dummy Elasticsearch container, and then the Elastalert container. When the Elastalert container starts, the `CMD` script runs through the following processes:

* Checks the Elastalert rules located in `${RULES_FOLDER}` if any exists
* Sets container timezone to `${CONTAINER_TIMEZONE}` if the `${SET_CONTAINER_TIMEZONE}` is set to `True`. The default is `Etc/UTC`.
* Starts the NTP daemon for time synchronization. This requires the following Linux capabilities set via `cap_add`: `SYS_NICE` and `SYS_TIME`.
* Populates the Elastalert template located at `${CONFIG_DIR}/elastalert_config.yaml.tmpl` with environment variables using the `dockerize` binary.
* Loops a `wget` command until the Elasticsearch instance located at `${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}` becomes available.
* Runs `elastalert-create-index` if the specified `${ELASTALERT_INDEX}` hasn't yet been created,
* Executes the `python` daemon.

## Credit
* Dockerize project for populating configuration templates: [jwilder/dockerize](https://github.com/jwilder/dockerize)
* Dumb-init system used for proper forking off of PID 1: [Yelp/dumb-init](https://github.com/Yelp/dumb-init)
* Much of this repositiory was based off of the `docker-elastalert` repo from krizsan: [krizsan/elastalert-docker](https://github.com/krizsan/elastalert-docker)

## Environment Variables

### Set at buildtime

These variables are set during the Docker build, and are generally necessary for running core functionality of Elastalert.

| Env var | Elastalert config var | Default | Description |
| :--- | :--- | :--- | :--- |
| CONFIG_FOLDER | N/A | `/opt/elastalert/config` | Place Elastalert configs here |
| CONTAINER_TIMEZONE | N/A | `Etc/UTC` | Container timezone value |
| DOCKERIZE_VERSION | N/A | `0.6.0` | Version of Dockerize binary to download |
| ELASTALERT_CONFIG | N/A | `${CONFIG_FOLDER}/elastalert_config.yaml` | Name and location of the config file referenced by `src/start-elastalert` to start the Python daemon |
| ELASTALERT_INDEX | `writeback_index` | `elastalert_status` | Name of the Elastalert index in your Elasticsearch cluster |
| ELASTALERT_SYSTEM_GROUP | N/A | `elastalert` | Name of the user running Elastalert; used for the daemon and folder permissions |
| ELASTALERT_SYSTEM_USER | N/A | `elastalert` | Name of the group running Elastalert; used for the daemon and folder permissions |
| ELASTALERT_VERSION | N/A | `0.1.29` | Version of Elastalert to install from `pip` |
| ELASTICSEARCH_HOST | `es_host` | `elasticsearch` | Desc |
| ELASTICSEARCH_PORT | `es_port` | `9200` | Desc |
| ELASTICSEARCH_USE_SSL | `use_ssl` | `False` | Connect with TLS to Elasticsearch |
| ELASTICSEARCH_VERIFY_CERTS | `verify_certs` | `False` | Use SSL authentication with client certificates |
| RULES_FOLDER | `rules_folder` | `/opt/elastalert/rules` | Folder where Elastalert scans for rules |
| SET_CONTAINER_TIMEZONE | N/A | `True` | Whether or not to set the container timezone to `${CONTAINER_TIMEZONE}` |

### Set at runtime

These variables are settings available in the Elastalert configuration file. Most of these settings apply to third-party integrations (JIRA, OpsGenie, etc), or are things documented here: [Elastalert common configuration options](https://elastalert.readthedocs.io/en/latest/ruletypes.html#common-configuration-options)

| Env var | Elastalert config var | Default | Description |
| :--- | :--- | :--- | :--- |
| ELASTALERT_AWS_REGION | `aws_region`| No default set |  |
| ELASTALERT_BUFFER_TIME | `buffer_time: => minutes:` | `45` | ElastAlert will buffer results from the most recent period of time, in case some log sources are not in real time
| ELASTALERT_EMAIL | `email`| No default set |  |
| ELASTALERT_EMAIL_REPLY_TO | `email_reply_to`| No default set |  |
| ELASTALERT_EXOTEL_ACCOUNT_SID | `exotel_account_sid`| No default set |  |
| ELASTALERT_EXOTEL_AUTH_TOKEN | `exotel_auth_token`| No default set |  |
| ELASTALERT_EXOTEL_FROM_NUMBER | `exotel_from_number`| No default set |  |
| ELASTALERT_EXOTEL_TO_NUMBER | `exotel_to_number`| No default set |  |
| ELASTALERT_FROM_ADDR | `from_addr`| No default set |  |
| ELASTALERT_GITTER_MSG_LEVEL | `gitter_msg_level`| No default set |  |
| ELASTALERT_GITTER_PROXY | `gitter_proxy`| No default set |  |
| ELASTALERT_GITTER_WEBHOOK_URL | `gitter_webhook_url`| No default set |  |
| ELASTALERT_HIPCHAT_AUTH_TOKEN | `hipchat_auth_token`| No default set |  |
| ELASTALERT_HIPCHAT_DOMAIN | `hipchat_domain`| No default set |  |
| ELASTALERT_HIPCHAT_FROM | `hipchat_from`| No default set |  |
| ELASTALERT_HIPCHAT_IGNORE_SSL_ERRORS | `hipchat_ignore_ssl_errors`| No default set |  |
| ELASTALERT_HIPCHAT_NOTIFY | `hipchat_notify`| No default set |  |
| ELASTALERT_HIPCHAT_ROOM_ID | `hipchat_room_id`| No default set |  |
| ELASTALERT_JIRA_ACCOUNT_FILE | `jira_account_file`| No default set |  |
| ELASTALERT_JIRA_ASSIGNEE | `jira_assignee`| No default set |  |
| ELASTALERT_JIRA_BUMP_IN_STATUSES | `jira_bump_in_statuses`| No default set |  |
| ELASTALERT_JIRA_BUMP_NOT_IN_STATUSES | `jira_bump_not_in_statuses`| No default set |  |
| ELASTALERT_JIRA_BUMP_TICKETS | `jira_bump_tickets`| No default set |  |
| ELASTALERT_JIRA_COMPONENT | `jira_component`| No default set |  |
| ELASTALERT_JIRA_COMPONENTS | `jira_components`| No default set |  |
| ELASTALERT_JIRA_ISSUETYPE | `jira_issuetype`| No default set |  |
| ELASTALERT_JIRA_LABEL | `jira_label`| No default set |  |
| ELASTALERT_JIRA_LABELS | `jira_labels`| No default set |  |
| ELASTALERT_JIRA_MAX_AGE | `jira_max_age`| No default set |  |
| ELASTALERT_JIRA_PROJECT | `jira_project`| No default set |  |
| ELASTALERT_JIRA_SERVER | `jira_server`| No default set |  |
| ELASTALERT_JIRA_WATCHERS | `jira_watchers`| No default set |  |
| ELASTALERT_NOTIFY_EMAIL | `notify_email`| No default set |  |
| ELASTALERT_OPSGENIE_ACCOUNT | `opsgenie_account`| No default set |  |
| ELASTALERT_OPSGENIE_ADDR | `opsgenie_addr`| No default set |  |
| ELASTALERT_OPSGENIE_ALIAS | `opsgenie_alias`| No default set |  |
| ELASTALERT_OPSGENIE_KEY | `opsgenie_key`| No default set |  |
| ELASTALERT_OPSGENIE_MESSAGE | `opsgenie_message`| No default set |  |
| ELASTALERT_OPSGENIE_PROXY | `opsgenie_proxy`| No default set |  |
| ELASTALERT_OPSGENIE_RECIPIENTS | `opsgenie_recipients`| No default set |  |
| ELASTALERT_OPSGENIE_TAGS | `opsgenie_tags`| No default set |  |
| ELASTALERT_OPSGENIE_TEAMS | `opsgenie_teams`| No default set |  |
| ELASTALERT_PAGERDUTY_CLIENT_NAME | `pagerduty_client_name`| No default set |  |
| ELASTALERT_PAGERDUTY_EVENT_TYPE | `pagerduty_event_type`| No default set |  |
| ELASTALERT_PAGERDUTY_SERVICE_KEY | `pagerduty_service_key`| No default set |  |
| ELASTALERT_RUN_EVERY | `run_every: => minutes:` | `3` | Number of minutes to wait before re-checking Elastalert rules. Currently only available as values in minutes |
| ELASTALERT_SLACK_EMOJI_OVERRIDE | `slack_emoji_override`| No default set |  |
| ELASTALERT_SLACK_ICON_URL_OVERRIDE | `slack_icon_url_override`| No default set |  |
| ELASTALERT_SLACK_MSG_COLOR | `slack_msg_color`| No default set |  |
| ELASTALERT_SLACK_PARSE_OVERRIDE | `slack_parse_override`| No default set |  |
| ELASTALERT_SLACK_TEXT_STRING | `slack_text_string`| No default set |  |
| ELASTALERT_SLACK_USERNAME_OVERRIDE | `slack_username_override`| No default set |  |
| ELASTALERT_SLACK_WEBHOOK_URL | `slack_webhook_url`| No default set |  |
| ELASTALERT_SMTP_HOST | `smtp_host`| No default set |  |
| ELASTALERT_TELEGRAM_API_URL | `telegram_api_url`| No default set |  |
| ELASTALERT_TELEGRAM_BOT_TOKEN | `telegram_bot_token`| No default set |  |
| ELASTALERT_TELEGRAM_ROOM_ID | `telegram_room_id`| No default set |  |
| ELASTALERT_TIME_LIMIT | `alert_time_limit: => minutes:`| `5` | If an alert fails for some reason, ElastAlert will retry sending the alert until this time period has elapsed |
| ELASTALERT_TWILIO_ACCOUNT_SID | `twilio_account_sid`| No default set |  |
| ELASTALERT_TWILIO_AUTH_TOKEN | `twilio_auth_token`| No default set |  |
| ELASTALERT_TWILIO_FROM_NUMBER | `twilio_from_number`| No default set |  |
| ELASTALERT_TWILIO_TO_NUMBER | `twilio_to_number`| No default set |  |
| ELASTALERT_VICTOROPS_API_KEY | `victorops_api_key`| No default set |  |
| ELASTALERT_VICTOROPS_ENTITY_DISPLAY_NAME | `victorops_entity_display_name`| No default set |  |
| ELASTALERT_VICTOROPS_MESSAGE_TYPE | `victorops_message_type`| No default set |  |
| ELASTALERT_VICTOROPS_ROUTING_KEY | `victorops_routing_key`| No default set |  |
| ELASTICSEARCH_CA_CERTS | `ca_certs`| No default set |  |
| ELASTICSEARCH_CLIENT_CERT | `client_cert`| No default set |  |
| ELASTICSEARCH_CLIENT_KEY | `client_key`| No default set |  |
| ELASTICSEARCH_PASSWORD | `es_password`| No default set |  |
| ELASTICSEARCH_SEND_GET_BODY_AS | `es_send_get_body_as`| No default set |  |
| ELASTICSEARCH_URL_PREFIX | `es_url_prefix`| No default set |  |
| ELASTICSEARCH_USER | `es_username`| No default set |  |

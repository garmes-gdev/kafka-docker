#!/usr/bin/env bash
set -e

if [[ -z "$CONNECT_BOOTSTRAP_SERVERS" ]]; then
    echo "CONNECT_BOOTSTRAP_SERVERS is unset"
    exit 1;
fi

# Write the config file
cat <<EOF
# REST Listeners
rest.port=8083
rest.advertised.host.name=$(hostname -I)
rest.advertised.port=8083

key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=true
value.converter.schemas.enable=true

internal.key.converter=org.apache.kafka.connect.json.JsonConverter
internal.value.converter=org.apache.kafka.connect.json.JsonConverter
internal.key.converter.schemas.enable=false
internal.value.converter.schemas.enable=false

group.id=kafka-connect
offset.storage.topic=connect-offsets
offset.storage.replication.factor=1

config.storage.topic=connect-configs
config.storage.replication.factor=1

status.storage.topic=connect-status
status.storage.replication.factor=1

#====== Provided configuration =======#

EOF

EXCLUSIONS="|KAFKA_HOME|JAVA_SYSTEM_PROPERTIES|KAFKA_VERSION|KAFKA_HOME|KAFKA_DEBUG|KAFKA_GC_LOG_OPTS|KAFKA_HEAP_OPTS|KAFKA_JMX_ENABLED|KAFKA_METRICS_ENABLED|KAFKA_LOG|KAFKA_OPTS|KAFKA_LOG4J_OPTS|"

# Read in env as a new-line separated array. This handles the case of env variables have spaces and/or carriage returns. See #313
IFS=$'\n'
for VAR in $(env)
do
    env_var=$(echo "$VAR" | cut -d= -f1)
    if [[ "$EXCLUSIONS" = *"|$env_var|"* ]]; then
        continue
    fi

    if [[ $env_var =~ ^CONNECT_ ]]; then
        kafka_name=$(echo "$env_var" | cut -d_ -f2- | tr '[:upper:]' '[:lower:]' | tr _ .)
        echo "$kafka_name=${!env_var}" 
    fi
done
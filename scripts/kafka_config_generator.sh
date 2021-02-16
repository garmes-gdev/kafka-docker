#!/usr/bin/env bash
set -e

if [[ -z "$KAFKA_ZOOKEEPER_CONNECT" ]]; then
    echo "KAFKA_ZOOKEEPER_CONNECT is unset"
    exit 1;
fi


cat <<EOF
# Default Kafka conf
log.dirs=/tmp/kafka-logs
num.partitions=1
num.recovery.threads.per.data.dir=1
default.replication.factor=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
queued.max.requests=16
#==================
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

    if [[ $env_var =~ ^KAFKA_ ]]; then
        kafka_name=$(echo "$env_var" | cut -d_ -f2- | tr '[:upper:]' '[:lower:]' | tr _ .)
        echo "$kafka_name=${!env_var}" 
    fi
done


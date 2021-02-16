#!/usr/bin/env bash
set -e

CUSTOM_CONFIG="$KAFKA_HOME/custom-config"
export CUSTOM_CONFIG
mkdir -p $CUSTOM_CONFIG

# volume for saving Zookeeper server logs
export ZOOKEEPER_VOLUME="$KAFKA_HOME/zookeeper/"
# base name for Zookeeper server data dir and application logs
export ZOOKEEPER_DATA_BASE_NAME="data"
export ZOOKEEPER_LOG_BASE_NAME="logs"

ZOOKEEPER_ID=0
export ZOOKEEPER_ID

# dir for saving application logs
export LOG_DIR=$ZOOKEEPER_VOLUME$ZOOKEEPER_LOG_BASE_NAME

# create data dir
export ZOOKEEPER_DATA_DIR=$ZOOKEEPER_VOLUME$ZOOKEEPER_DATA_BASE_NAME
mkdir -p $ZOOKEEPER_DATA_DIR

# Create myid file
echo "$ZOOKEEPER_ID" > $ZOOKEEPER_DATA_DIR/myid

mkdir -p /tmp/zookeeper


# Generate and print the config file
echo "Starting Zookeeper with configuration:"
./zookeeper_config_generator.sh | tee $CUSTOM_CONFIG/zookeeper.properties
echo ""

if [ -z "$KAFKA_LOG4J_OPTS" ]; then
  ./log4j_config_generator.sh | tee $CUSTOM_CONFIG/log4j.properties
  export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:$CUSTOM_CONFIG/log4j.properties"
fi

# enabling Prometheus JMX exporter as Java agent
if [ "$ZOOKEEPER_METRICS_ENABLED" = "true" ]; then
  ./jmx_config_generator.sh | tee $CUSTOM_CONFIG/metrics-config.yml
  KAFKA_OPTS="$KAFKA_OPTS -javaagent:$(ls "$KAFKA_HOME"/libs/jmx_prometheus_javaagent*.jar)=50700:$CUSTOM_CONFIG/metrics-config.yml"
  export KAFKA_OPTS
fi

if [ -z "$KAFKA_HEAP_OPTS" ] && [ -n "${DYNAMIC_HEAP_FRACTION}" ]; then
    . ./dynamic_resources.sh
    # Calculate a max heap size based some DYNAMIC_HEAP_FRACTION of the heap
    # available to a jvm using 100% of the GCroup-aware memory
    # up to some optional DYNAMIC_HEAP_MAX
    CALC_MAX_HEAP=$(get_heap_size "${DYNAMIC_HEAP_FRACTION}" "${DYNAMIC_HEAP_MAX}")
    if [ -n "$CALC_MAX_HEAP" ]; then
      export KAFKA_HEAP_OPTS="-Xms${CALC_MAX_HEAP} -Xmx${CALC_MAX_HEAP}"
    fi
fi

. ./set_kafka_gc_options.sh

if [ -n "$JAVA_SYSTEM_PROPERTIES" ]; then
    export KAFKA_OPTS="${KAFKA_OPTS} ${JAVA_SYSTEM_PROPERTIES}"
fi

# We need to disable the native ZK authorisation (we secure ZK through the TLS-Sidecars) to allow use of the reconfiguration options.
KAFKA_OPTS="$KAFKA_OPTS -Dzookeeper.skipACL=yes"
export KAFKA_OPTS

echo "KAFKA_OPTS[${KAFKA_OPTS}]"
# starting Zookeeper with final configuration
exec /usr/bin/tini -w -e 143 -- "${KAFKA_HOME}/bin/zookeeper-server-start.sh" $CUSTOM_CONFIG/zookeeper.properties

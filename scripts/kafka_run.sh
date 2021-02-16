#!/usr/bin/env bash
set -e
set -x

CUSTOM_CONFIG="$KAFKA_HOME/custom-config"
export CUSTOM_CONFIG
mkdir -p $CUSTOM_CONFIG

KAFKA_BROKER_ID=0
export KAFKA_BROKER_ID
echo "BROKER_ID=${KAFKA_BROKER_ID}"

# Disable Kafka's GC logging (which logs to a file)...
export GC_LOG_ENABLED="false"

if [ -z "$KAFKA_LOG4J_OPTS" ]; then
  ./log4j_config_generator.sh | tee $CUSTOM_CONFIG/log4j.properties
  export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:$CUSTOM_CONFIG/log4j.properties"
fi

if [ "$KAFKA_JMX_ENABLED" = "true" ]; then
  KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote.port=9999 -Dcom.sun.management.jmxremote.rmi.port=9999 -Dcom.sun.management.jmxremote=true -Djava.rmi.server.hostname=$(hostname -i) -Djava.net.preferIPv4Stack=true"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"
fi


if [ -n "$JAVA_SYSTEM_PROPERTIES" ]; then
    export KAFKA_OPTS="${KAFKA_OPTS} ${JAVA_SYSTEM_PROPERTIES}"
fi

KAFKA_OPTS="${KAFKA_OPTS} ${KAFKA_JMX_OPTS}"

# enabling Prometheus JMX exporter as Java agent
if [ "$KAFKA_METRICS_ENABLED" = "true" ]; then
  KAFKA_OPTS="${KAFKA_OPTS} -javaagent:$(ls "$KAFKA_HOME"/libs/jmx_prometheus_javaagent*.jar)=50700:$KAFKA_HOME/custom-config/metrics-config.yml"
  export KAFKA_OPTS
fi

# We don't need LOG_DIR because we write no log files, but setting it to a
# directory avoids trying to create it (and logging a permission denied error)
export LOG_DIR="$KAFKA_HOME"

mkdir -p /tmp/kafka

# Generate and print the config file
echo "Starting Kafka with configuration:"
./kafka_config_generator.sh | tee $CUSTOM_CONFIG/kafka.properties 
echo ""

if [ -z "$KAFKA_HEAP_OPTS" ] && [ -n "${DYNAMIC_HEAP_FRACTION}" ]; then
    . ./dynamic_resources.sh
    # Calculate a max heap size based some DYNAMIC_HEAP_FRACTION of the heap
    # available to a jvm using 100% of the CGroup-aware memory
    # up to some optional DYNAMIC_HEAP_MAX
    CALC_MAX_HEAP=$(get_heap_size "${DYNAMIC_HEAP_FRACTION}" "${DYNAMIC_HEAP_MAX}")
    if [ -n "$CALC_MAX_HEAP" ]; then
      export KAFKA_HEAP_OPTS="-Xms${CALC_MAX_HEAP} -Xmx${CALC_MAX_HEAP}"
    fi
fi

. ./set_kafka_gc_options.sh

# starting Kafka server with final configuration
exec /usr/bin/tini -w -e 143 -- "${KAFKA_HOME}/bin/kafka-server-start.sh" $CUSTOM_CONFIG/kafka.properties

#!/usr/bin/env bash
set -e

# Write the config file
cat <<EOF
# The directory where the snapshot is stored.
dataDir=${ZOOKEEPER_DATA_DIR}

# Other options
4lw.commands.whitelist=*
clientPort=2181
maxClientCnxns=0
admin.enableServer=false

# Provided configuration
${ZOOKEEPER_CONFIGURATION}
EOF

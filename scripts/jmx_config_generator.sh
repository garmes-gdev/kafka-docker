#!/usr/bin/env bash
set -e

# Write the config file
cat <<EOF
---
startDelaySeconds: 0
ssl: false
lowercaseOutputName: false
lowercaseOutputLabelNames: false
whitelistObjectNames: ["*:*"]
EOF
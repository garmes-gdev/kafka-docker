#!/usr/bin/env bash
set -e

COMPONENTS="|zookeeper|kafka|connect|"

if [ "x$COMPONENT" = 'x' ]; then
    echo "COMPONENT not defined"
    exit 1
fi;

if [[ "$COMPONENTS" = *"|$COMPONENT|"* ]]; then
	./${COMPONENT}_run.sh 
else
    echo "unknown component ${COMPONENT}"
    exit 1;
fi

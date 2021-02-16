#!/usr/bin/env bash
set -e

if [ "x$KAFKA_VERSION" = 'x' ]; then
    echo "KAFKA_VERSION not defined"
    exit 1
fi;


echo "Build kafka docker image ${KAFKA_VERSION}"

SCALA_VERSION="2.13"
export SCALA_VERSION

MAJOR_VERSION=$(echo "${KAFKA_VERSION}" | cut -d. -f1)
export MAJOR_VERSION

MINOR_VERSION=$(echo "{$KAFKA_VERSION}" | cut -d. -f2)
export MINOR_VERSION

TMP_DIR="./tmp"
test -d "$TMP_DIR" || mkdir -p "$TMP_DIR"

#-------- download -----------
FILENAME="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
url="https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/${FILENAME}"

KAFKA_TGZ="${TMP_DIR}/${FILENAME}"

if test -f "${KAFKA_TGZ}"; then
	echo "${KAFKA_TGZ} exists, skip download(^_^)"
else
	echo "Downloading Kafka from $url"
    wget "${url}" -O "${KAFKA_TGZ}"
fi;

#---------------------------

KAFKA_DIST_DIR="${TMP_DIR}/$KAFKA_VERSION"

test -d "${KAFKA_DIST_DIR}" && rm -r "${KAFKA_DIST_DIR}"
mkdir -p "${KAFKA_DIST_DIR}"
echo "Unpacking binary archive"
tar xvfz "${KAFKA_TGZ}" -C "${KAFKA_DIST_DIR}" --strip-components=1

echo "KAFKA_DIST_DIR=${KAFKA_DIST_DIR}"

docker build -t mgarmes/kafka \
--build-arg KAFKA_VERSION=${KAFKA_VERSION} \
--build-arg KAFKA_DIST_DIR=${KAFKA_DIST_DIR} \
.

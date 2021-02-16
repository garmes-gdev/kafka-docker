FROM centos:7

MAINTAINER Mohammed GARMES

ENV LANG="C.UTF-8"

ARG JAVA_VERSION=11

RUN yum -y update \
    && yum -y install java-${JAVA_VERSION}-openjdk-headless openssl bind-utils \
    && yum -y clean all

#####
# Add Tini
#####
ENV TINI_VERSION v0.18.0
ENV TINI_SHA256=12d20136605531b09a2c2dac02ccee85e1b874eb322ef6baf7561cd93f93c855
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN echo "${TINI_SHA256} */usr/bin/tini" | sha256sum -c \
    && chmod +x /usr/bin/tini

RUN yum -y install gettext nmap-ncat net-tools && yum clean all -y

RUN echo "===>  Installing Prometheus exporter ..." \
    && mkdir -p /opt/prometheus \
    && curl "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.15.0/jmx_prometheus_javaagent-0.15.0.jar" \
          -o /opt/prometheus/jmx_prometheus_javaagent-0.15.0.jar \
    && chmod 444 /opt/prometheus/jmx_prometheus_javaagent-0.15.0.jar

RUN unlink /etc/localtime && ln -s /usr/share/zoneinfo/UTC /etc/localtime

# Add kafka user with UID 1001
# The user is in the group 0 to have access to the mounted volumes and storage
RUN useradd -r -m -u 1001 -g 0 kafka

ARG KAFKA_DIST_DIR
ARG KAFKA_VERSION

#####
# Add Kafka
#####
ENV KAFKA_HOME=/opt/kafka
ENV KAFKA_VERSION=${KAFKA_VERSION}


COPY $KAFKA_DIST_DIR $KAFKA_HOME
COPY ./scripts/ $KAFKA_HOME

RUN chown -R 1001:1001 /opt/kafka

WORKDIR $KAFKA_HOME

USER 1001

CMD ["/opt/kafka/main_run.sh"]

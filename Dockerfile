# Kafka client-only utilities image (Kafka 4.0)
# - Stage 1 (builder): fetch and prune Kafka, collect minimal shell tooling
# - Stage 2 (final): distroless Java 17 (nonroot) with only client tools + runtime deps

# -----------------------------
# Stage 1: Builder & packager
# -----------------------------
FROM debian:12-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Versions can be overridden at build time
ARG KAFKA_VERSION=4.0.0
ARG SCALA_VERSION=2.13
# If DOWNLOAD_URL is provided (via --build-arg or environment passthrough), it will be used
ARG DOWNLOAD_URL
ENV DOWNLOAD_URL=${DOWNLOAD_URL}

ENV KAFKA_HOME=/opt/kafka
ENV RUNTIME_STAGING=/opt/runtime

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    bash \
    coreutils \
    findutils \
    gawk \
    grep \
    sed \
    procps \
    tar \
    xz-utils; \
  rm -rf /var/lib/apt/lists/*

# Download Kafka tarball (use DOWNLOAD_URL if set; otherwise try Apache CDN then archive)
RUN set -eux; \
  mkdir -p "${KAFKA_HOME}"; \
  : "+ Downloading Kafka ${KAFKA_VERSION} (Scala ${SCALA_VERSION})"; \
  default_url="https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"; \
  archive_url="https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"; \
  url="${DOWNLOAD_URL:-}"; \
  if [ -z "$url" ]; then url="$default_url"; fi; \
  for candidate in "$url" "$archive_url"; do \
    echo "Trying: $candidate"; \
    if curl -fL --retry 5 --retry-delay 2 -o /tmp/kafka.tgz "$candidate"; then \
      break; \
    fi; \
  done; \
  [ -s /tmp/kafka.tgz ] || { echo "Failed to download Kafka" >&2; exit 1; }; \
  tar --strip-components=1 -xzf /tmp/kafka.tgz -C "${KAFKA_HOME}" --wildcards '*/bin/*' '*/libs/*'; \
  rm -f /tmp/kafka.tgz

# Prune non-client scripts; keep client tools and runner
# Keep list includes (non-exhaustive):
# - kafka-topics.sh, kafka-console-producer.sh, kafka-console-consumer.sh
# - kafka-consumer-groups.sh, kafka-configs.sh, kafka-reassign-partitions.sh
# - kafka-leader-election.sh, kafka-delegation-tokens.sh, kafka-broker-api-versions.sh
# - kafka-producer-perf-test.sh, kafka-consumer-perf-test.sh, kafka-get-offsets.sh, kafka-features.sh
# - kafka-run-class.sh (required by all scripts)
RUN set -eux; cd "${KAFKA_HOME}/bin"; \
  chmod +x *.sh || true; \
  rm -f *.bat || true; \
  rm -f \
    kafka-server-start.sh \
    kafka-server-stop.sh \
    kafka-storage.sh \
    kafka-metadata-quorum.sh \
    kafka-metadata-service.sh \
    zookeeper-* \
    kafka-mirror-maker.sh \
    kafka-mirror-maker2.sh \
    kafka-connect-* \
    connect-* \
    trogdor.sh \
    kafka-docker* \
    kafka-broker-start.sh \
    kafka-broker-stop.sh || true

## No need to collect runtime binaries here; final stage will install needed tools

# -----------------------------
# Stage 2: Runtime (Alpine + Java 17)
# -----------------------------
FROM amazoncorretto:17-alpine3.20 AS runtime

ENV KAFKA_HOME=/opt/kafka
ENV PATH="/opt/kafka/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
## Provide a sensible default heap for Kafka client tools. Override at runtime with:
##   docker run -e KAFKA_HEAP_OPTS="-Xms512m -Xmx2g" ...
## You can also adjust container memory limits via --memory to influence JVM sizing.
ENV KAFKA_HEAP_OPTS="-Xms256m -Xmx1024m"

RUN set -eux; \
  apk add --no-cache \
    bash \
    tini

# Copy Kafka client tools
COPY --from=builder /opt/kafka /opt/kafka

WORKDIR /opt/kafka

# Link client scripts into PATH for easy invocation
RUN ln -s /opt/kafka/bin/*.sh /usr/local/bin/

# Let users run tools directly, e.g.: docker run --rm <img> kafka-topics.sh --help
ENTRYPOINT ["/sbin/tini","--"]
CMD ["bash"]

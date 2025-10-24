ARG RELEASE=RELEASE.2025-10-15T17-29-55Z

# Build stage - compile MinIO from source
FROM golang:1.24-alpine@sha256:ac60270c8394bda77031017f1adc2c2861f9300a12985055ec4d3e4725c18bb4 AS build

ARG TARGETARCH
ARG RELEASE

ENV GOPATH=/go
ENV CGO_ENABLED=0

WORKDIR /build

# Install build tools
RUN apk add -U --no-cache ca-certificates git make

# Clone MinIO source at specific release tag and build
# Use build cache mounts to significantly speed up compilation
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    git clone --depth 1 --branch ${RELEASE} https://github.com/minio/minio.git && \
    cd minio && \
    go build -o /go/bin/minio -trimpath -tags kqueue -ldflags "-s -w" .

# Build MinIO Client (mc) from source
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    git clone --depth 1 https://github.com/minio/mc.git && \
    cd mc && \
    go build -o /go/bin/mc -trimpath -ldflags "-s -w" .

# Verify binaries were built successfully
RUN test -x /go/bin/minio && \
    test -x /go/bin/mc && \
    echo "Binary compilation complete:" && \
    ls -lh /go/bin/minio /go/bin/mc

# Create user in build stage for later copying
RUN echo "minio:x:1000:1000:MinIO User:/home/minio:/bin/sh" >> /tmp/passwd && \
    echo "minio:x:1000:" >> /tmp/group

# Runtime stage
FROM registry.access.redhat.com/ubi9/ubi-micro:latest@sha256:a14963edf4631d8a4b99bb8ec7206c804c4d1f3c1a6c9ca58d5059553a52f992

ARG RELEASE

LABEL org.opencontainers.image.source="https://github.com/zOnlyKroks/container-images" \
      org.opencontainers.image.description="MinIO High-Performance Object Storage (Security-First, Built from Source)" \
      org.opencontainers.image.version="${RELEASE}" \
      org.opencontainers.image.vendor="zOnlyKroks" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      name="MinIO" \
      vendor="MinIO Inc <dev@min.io>" \
      maintainer="zOnlyKroks" \
      version="${RELEASE}" \
      release="${RELEASE}" \
      summary="MinIO is a High Performance Object Storage, API compatible with Amazon S3 cloud storage service."

# Environment variables for MinIO
# hadolint ignore=DL3003,DL4006,SC2086
# IMPORTANT: MINIO_ROOT_USER and MINIO_ROOT_PASSWORD must be set at runtime
# MinIO will not start without credentials. Set them via:
#   docker run -e MINIO_ROOT_USER=myadmin -e MINIO_ROOT_PASSWORD=mysecretpassword ...
# Or use Docker secrets/Kubernetes secrets in production

# File-based credential paths (for Docker/Kubernetes secrets)
# These variables contain FILE PATHS, not secrets themselves - they tell MinIO where to read secrets from
# checkov:skip=CKV_DOCKER_3: These are file paths for secret mounting, not actual secrets
ENV MINIO_ACCESS_KEY_FILE=access_key \
    MINIO_SECRET_KEY_FILE=secret_key \
    MINIO_ROOT_USER_FILE=access_key \
    MINIO_ROOT_PASSWORD_FILE=secret_key \
    MINIO_KMS_SECRET_KEY_FILE=kms_master_key \
    MINIO_UPDATE_MINISIGN_PUBKEY="RWTx5Zr1tiHQLwG9keckT0c45M3AGeHD6IvimQHpyRywVWGbP1aVSGav" \
    MINIO_CONFIG_ENV_FILE=config.env \
    MC_CONFIG_DIR=/tmp/.mc

# Copy CA certificates
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy user configuration from build stage
COPY --from=build /tmp/passwd /tmp/group /tmp/

# Copy verified binaries
COPY --from=build /go/bin/minio /usr/bin/minio
COPY --from=build /go/bin/mc /usr/bin/mc

# Copy entrypoint script
COPY entrypoint.sh /usr/bin/docker-entrypoint.sh

# Setup user and permissions
RUN cat /tmp/passwd >> /etc/passwd && \
    cat /tmp/group >> /etc/group && \
    rm /tmp/passwd /tmp/group && \
    chmod +x /usr/bin/minio /usr/bin/mc /usr/bin/docker-entrypoint.sh && \
    mkdir -p /data /tmp/.mc /home/minio/.minio/certs && \
    chown -R 1000:1000 /data /tmp/.mc /home/minio

USER 1000:1000

EXPOSE 9000 9001

VOLUME ["/data"]

# Set working directory to user home
WORKDIR /home/minio

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["minio", "server", "/data", "--console-address", ":9001"]

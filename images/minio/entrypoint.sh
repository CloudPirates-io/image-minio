#!/bin/sh
set -e

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1"
}

if [ -z "${MINIO_ROOT_USER}" ] && [ ! -f "${MINIO_ROOT_USER_FILE:-/nonexistent}" ]; then
    log_error "MINIO_ROOT_USER or MINIO_ROOT_USER_FILE must be set"
    exit 1
fi

if [ -z "${MINIO_ROOT_PASSWORD}" ] && [ ! -f "${MINIO_ROOT_PASSWORD_FILE:-/nonexistent}" ]; then
    log_error "MINIO_ROOT_PASSWORD or MINIO_ROOT_PASSWORD_FILE must be set"
    exit 1
fi

if [ -n "${MINIO_ROOT_PASSWORD}" ] && [ ${#MINIO_ROOT_PASSWORD} -lt 8 ]; then
    log_error "MINIO_ROOT_PASSWORD must be at least 8 characters"
    exit 1
fi

DATA_DIR="${1:-/data}"
if [ ! -d "${DATA_DIR}" ]; then
    log_error "Data directory ${DATA_DIR} does not exist"
    exit 1
fi

[ -z "${MINIO_JSON_LOGGING}" ] && export MINIO_JSON_LOGGING="on"
[ -z "${MINIO_BROWSER_LOGIN_ANIMATION}" ] && export MINIO_BROWSER_LOGIN_ANIMATION="off"

log_info "Starting MinIO as $(id -u):$(id -g)"

exec "$@"

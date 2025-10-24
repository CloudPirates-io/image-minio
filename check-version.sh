#!/bin/bash
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Detect OS for sed compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE="sed -i.bak"
  SED_CLEANUP="rm -f"
else
  SED_INPLACE="sed -i"
  SED_CLEANUP="true"
fi

# Function to get the latest digest for a Docker image
get_image_digest() {
  local image=$1
  local tag=$2

  # Use Docker Hub API or registry API to get the digest
  if [[ $image == *"registry.access.redhat.com"* ]]; then
    # For Red Hat registry, query directly without authentication (public images)
    local digest=$(curl -sL \
      -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
      "https://${image}/manifests/${tag}" \
      -I 2>/dev/null | grep -i docker-content-digest | awk '{print $2}' | tr -d '\r')

    echo "$digest"
  else
    # For Docker Hub images
    local repo=${image#docker.io/}
    repo=${repo#library/}

    # Get token for Docker Hub API
    local token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" | jq -r '.token')

    # Get manifest digest
    local digest=$(curl -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
      -H "Authorization: Bearer $token" \
      "https://registry-1.docker.io/v2/${repo}/manifests/${tag}" \
      -I | grep -i docker-content-digest | awk '{print $2}' | tr -d '\r')

    echo "$digest"
  fi
}

echo "=== Checking for updates ==="

# Get current version from Containerfile
CURRENT_VERSION=$(grep "ARG RELEASE=" Containerfile | head -1 | cut -d'=' -f2)
echo "Current MinIO version: $CURRENT_VERSION"

# Fetch latest release from GitHub
LATEST_VERSION=$(curl -s https://api.github.com/repos/minio/minio/releases/latest | jq -r '.tag_name')
echo "Latest MinIO version: $LATEST_VERSION"

# Extract current base images and their digests
GOLANG_IMAGE=$(grep "FROM golang:" Containerfile | head -1)
GOLANG_TAG=$(echo "$GOLANG_IMAGE" | sed 's/.*golang:\([^@]*\).*/\1/')
CURRENT_GOLANG_DIGEST=$(echo "$GOLANG_IMAGE" | grep -oP 'sha256:[a-f0-9]+' || echo "")

UBI_IMAGE=$(grep "FROM registry.access.redhat.com/ubi9/ubi-micro:" Containerfile | head -1)
UBI_TAG=$(echo "$UBI_IMAGE" | sed 's/.*ubi-micro:\([^@]*\).*/\1/')
CURRENT_UBI_DIGEST=$(echo "$UBI_IMAGE" | grep -oP 'sha256:[a-f0-9]+' || echo "")

echo ""
echo "=== Checking base image updates ==="
echo "Current golang image: $GOLANG_TAG"
echo "Current golang digest: $CURRENT_GOLANG_DIGEST"
echo "Current UBI image: $UBI_TAG"
echo "Current UBI digest: $CURRENT_UBI_DIGEST"

# Get latest digests for base images
echo ""
echo "Fetching latest golang:$GOLANG_TAG digest..."
LATEST_GOLANG_DIGEST=$(get_image_digest "golang" "$GOLANG_TAG")

echo "Fetching latest UBI9 ubi-micro:$UBI_TAG digest..."
LATEST_UBI_DIGEST=$(get_image_digest "registry.access.redhat.com/ubi9/ubi-micro" "$UBI_TAG")

UPDATE_NEEDED=false

# Check if MinIO version update is needed
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ] && [[ "$LATEST_VERSION" > "$CURRENT_VERSION" ]]; then
  echo ""
  echo "✓ MinIO update available: $CURRENT_VERSION -> $LATEST_VERSION"
  UPDATE_NEEDED=true

  # Update Containerfile
  $SED_INPLACE "s|ARG RELEASE=$CURRENT_VERSION|ARG RELEASE=$LATEST_VERSION|g" Containerfile
  $SED_CLEANUP Containerfile.bak 2>/dev/null || true

  # Update config.yaml - version field
  $SED_INPLACE "s|version: \"$CURRENT_VERSION\"|version: \"$LATEST_VERSION\"|g" config.yaml
  $SED_CLEANUP config.yaml.bak 2>/dev/null || true

  # Update config.yaml - build_args RELEASE field
  $SED_INPLACE "s|RELEASE: \"$CURRENT_VERSION\"|RELEASE: \"$LATEST_VERSION\"|g" config.yaml
  $SED_CLEANUP config.yaml.bak 2>/dev/null || true
else
  echo "✓ MinIO is up to date"
fi

# Check if golang base image digest update is needed
if [ -n "$LATEST_GOLANG_DIGEST" ] && [ "$CURRENT_GOLANG_DIGEST" != "$LATEST_GOLANG_DIGEST" ]; then
  echo ""
  echo "✓ Golang base image digest update available"
  echo "  Old: $CURRENT_GOLANG_DIGEST"
  echo "  New: $LATEST_GOLANG_DIGEST"
  UPDATE_NEEDED=true

  # Update Containerfile with new digest
  $SED_INPLACE "s|golang:${GOLANG_TAG}@${CURRENT_GOLANG_DIGEST}|golang:${GOLANG_TAG}@${LATEST_GOLANG_DIGEST}|g" Containerfile
  $SED_CLEANUP Containerfile.bak 2>/dev/null || true
else
  echo "✓ Golang base image is up to date"
fi

# Check if UBI base image digest update is needed
echo ""
if [ -n "$LATEST_UBI_DIGEST" ] && [ "$CURRENT_UBI_DIGEST" != "$LATEST_UBI_DIGEST" ]; then
  echo "✓ UBI base image digest update available"
  echo "  Old: $CURRENT_UBI_DIGEST"
  echo "  New: $LATEST_UBI_DIGEST"
  UPDATE_NEEDED=true

  # Update Containerfile with new digest
  $SED_INPLACE "s|ubi-micro:${UBI_TAG}@${CURRENT_UBI_DIGEST}|ubi-micro:${UBI_TAG}@${LATEST_UBI_DIGEST}|g" Containerfile
  $SED_CLEANUP Containerfile.bak 2>/dev/null || true
else
  echo "✓ UBI base image is up to date"
fi

if [ "$UPDATE_NEEDED" = true ]; then
  # Get release notes
  RELEASE_NOTES=$(curl -s https://api.github.com/repos/minio/minio/releases/latest | jq -r '.body' | head -20)

  echo ""
  echo "=== Updates applied ==="

  # Set outputs for GitHub Action
  if [ -n "$GITHUB_OUTPUT" ]; then
    # shellcheck disable=SC2129
    echo "update_available=true" >> "$GITHUB_OUTPUT"
    echo "current_version=$CURRENT_VERSION" >> "$GITHUB_OUTPUT"
    echo "new_version=$LATEST_VERSION" >> "$GITHUB_OUTPUT"
    {
      echo "release_notes<<EOF"
      echo "$RELEASE_NOTES"
      echo "EOF"
    } >> "$GITHUB_OUTPUT"
  fi

  exit 0
else
  echo ""
  echo "=== All components are up to date ==="
  [ -n "$GITHUB_OUTPUT" ] && echo "update_available=false" >> "$GITHUB_OUTPUT"
  exit 0
fi
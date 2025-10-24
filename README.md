# Container Images

Container images built from official sources. Multi-platform builds (amd64/arm64) scanned with Trivy.

**We do NOT patch application sources** - all images are built straight from upstream without modifications.

## Available Images

### MinIO
- **Docker Hub:** `cloudpirates/image-minio`
- **GHCR:** `ghcr.io/cloudpirates/image-minio/minio`

## Building

Images are built via GitHub Actions workflow. Go to **Actions → Build and Publish Container Images → Run workflow**

## Image Verification

Images are signed with Cosign. Verify signatures:

```bash
# Verify Docker Hub image
cosign verify --key cosign.pub cloudpirates/image-minio:latest

# Verify GHCR image
cosign verify --key cosign.pub ghcr.io/cloudpirates/image-minio/minio:latest

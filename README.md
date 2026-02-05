# Container Images

Container images built from official sources. Multi-platform builds (amd64/arm64) scanned with Trivy.

## Available Images

### MinIO

We provide two variants of the MinIO image:

#### Vanilla (Default)
Built straight from official MinIO source without any modifications.

- **Docker Hub:** `cloudpirates/image-minio:latest`
- **GHCR:** `ghcr.io/cloudpirates/image-minio/minio:latest`

```bash
# Pull vanilla image
docker pull cloudpirates/image-minio:latest
docker pull ghcr.io/cloudpirates/image-minio/minio:latest
```

#### Hardened
Built from official MinIO source with security patches applied for CVE fixes.

- **Docker Hub:** `cloudpirates/image-minio:RELEASE.VERSION-hardened`
- **GHCR:** `ghcr.io/cloudpirates/image-minio/minio:RELEASE.VERSION-hardened`

```bash
# Pull hardened image
docker pull cloudpirates/image-minio:RELEASE.2025-10-15T17-29-55Z-hardened
docker pull ghcr.io/cloudpirates/image-minio/minio:RELEASE.2025-10-15T17-29-55Z-hardened
```

**Security patches** are maintained in `images/minio/patches/` - see the [patches README](images/minio/patches/README.md) for details.

## Building

Images are built via GitHub Actions workflow. Go to **Actions → Build and Publish Container Images → Run workflow**

### Build Options

- **images**: Which images to build (`all` or comma-separated list)
- **build_variant**: Choose `vanilla`, `hardened`, or `all` (builds both)
- **push_to_dockerhub**: Push to Docker Hub
- **push_to_ghcr**: Push to GitHub Container Registry
- **sign_images**: Sign images with Cosign
- **run_security_scan**: Run Trivy security scan

## Image Verification

Images are signed with Cosign. Verify signatures:

```bash
# Verify vanilla Docker Hub image
cosign verify --key cosign.pub cloudpirates/image-minio:latest

# Verify hardened Docker Hub image
cosign verify --key cosign.pub cloudpirates/image-minio:RELEASE.2025-10-15T17-29-55Z-hardened

# Verify vanilla GHCR image
cosign verify --key cosign.pub ghcr.io/cloudpirates/image-minio/minio:latest

# Verify hardened GHCR image
cosign verify --key cosign.pub ghcr.io/cloudpirates/image-minio/minio:RELEASE.2025-10-15T17-29-55Z-hardened

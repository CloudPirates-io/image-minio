# Container Images

Container images built from official sources. Multi-platform builds (amd64/arm64) scanned with Trivy.

**We do NOT patch application sources** - all images are built straight from upstream without modifications.

## Available Images

### MinIO
- **Docker Hub:** `zonlykroks/minio`
- **GHCR:** `ghcr.io/zonlykroks/container-images/minio`

### OpenLDAP
- **Docker Hub:** `zonlykroks/openldap`
- **GHCR:** `ghcr.io/zonlykroks/container-images/openldap`

## Building

Images are built via GitHub Actions workflow. Go to **Actions → Build and Publish Container Images → Run workflow**

## Image Verification

Images are signed with Cosign. Verify signatures:

```bash
# Verify Docker Hub image
cosign verify --key cosign.pub zonlykroks/minio:latest

# Verify GHCR image
cosign verify --key cosign.pub ghcr.io/cloudpirates/container-images/minio:latest
```

## Contributing

1. Create a new directory under `images/` with the image name
2. Add `Dockerfile` and `config.yaml`
3. Optionally add `check-version.sh` for automated version checking
4. Test locally
5. Submit a pull request

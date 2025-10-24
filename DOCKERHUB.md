# MinIO - High-Performance Object Storage

Multi-architecture MinIO container built from official source, compatible with Amazon S3 API.

**GitHub Repository**: https://github.com/zOnlyKroks/container-images

## Quick Start

```bash
# Basic usage (set credentials via environment)
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=myadmin \
  -e MINIO_ROOT_PASSWORD=mysecretpassword \
  -v minio-data:/data \
  zonlykroks/minio:latest

# Access the console at http://localhost:9001
# API endpoint at http://localhost:9000
```

## Features

- Built from official MinIO source (RELEASE.2025-10-15T17-29-55Z)
- Multi-platform support: `linux/amd64`, `linux/arm64`
- Based on Red Hat UBI9 Micro (minimal attack surface)
- Includes MinIO Client (mc) for administration
- Amazon S3 compatible API
- No modifications to upstream source
- Trivy security scanning
- Cosign image signing

## Image Details

- **Base Image**: Red Hat UBI9 Micro
- **MinIO Version**: RELEASE.2025-10-15T17-29-55Z
- **Registry**: Docker Hub (`zonlykroks/minio`)
- **Alternate Registry**: GHCR (`ghcr.io/zonlykroks/container-images/minio`)

## Required Configuration

MinIO requires credentials to start. Set them using environment variables:

### Environment Variables

```bash
docker run -d \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=supersecret123 \
  zonlykroks/minio:latest
```

### Using Docker Secrets (Recommended for Production)

```bash
# Create secrets
echo "admin" | docker secret create minio_root_user -
echo "supersecret123" | docker secret create minio_root_password -

# Run with secrets
docker run -d \
  -e MINIO_ROOT_USER_FILE=/run/secrets/minio_root_user \
  -e MINIO_ROOT_PASSWORD_FILE=/run/secrets/minio_root_password \
  --secret minio_root_user \
  --secret minio_root_password \
  zonlykroks/minio:latest
```

## Ports

- `9000` - S3 API endpoint
- `9001` - Web console

## Volumes

- `/data` - Object storage data directory

## Configuration Options

MinIO can be configured via environment variables. Common options:

```bash
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=supersecret123 \
  -e MINIO_BROWSER=on \
  -e MINIO_DOMAIN=minio.example.com \
  -e MINIO_SERVER_URL=https://minio.example.com \
  -v minio-data:/data \
  zonlykroks/minio:latest
```

See [MinIO documentation](https://min.io/docs/minio/linux/reference/minio-server/minio-server.html) for all available options.

## Using MinIO Client (mc)

The image includes the MinIO Client for administration:

```bash
# Configure mc to connect to your MinIO instance
docker exec -it <container-id> mc alias set myminio http://localhost:9000 admin supersecret123

# List buckets
docker exec -it <container-id> mc ls myminio

# Create a bucket
docker exec -it <container-id> mc mb myminio/mybucket

# Copy files
docker exec -it <container-id> mc cp /path/to/file myminio/mybucket/
```

## Health Check

Built-in health check uses `mc ready` to verify MinIO is responding correctly.

## Distributed Mode

For production deployments with multiple nodes:

```bash
# Node 1
docker run -d \
  -p 9000:9000 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=supersecret123 \
  -v /mnt/data1:/data1 \
  -v /mnt/data2:/data2 \
  zonlykroks/minio:latest \
  minio server \
  http://node{1...4}/data{1...2} \
  --console-address ":9001"
```

See [MinIO distributed setup guide](https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-multi-node-multi-drive.html) for details.

## Security

- Images scanned with Trivy for vulnerabilities
- Signed with Cosign for supply chain security
- Minimal runtime dependencies (UBI9 Micro base)
- Built from unmodified upstream source
- Supports TLS/SSL encryption
- File-based credential loading for secrets management

### Image Verification

```bash
# Verify signature
cosign verify --key cosign.pub zonlykroks/minio:latest
```

Public key available at: https://github.com/zOnlyKroks/container-images/blob/main/cosign.pub

### Enabling TLS

```bash
docker run -d \
  -p 9000:9000 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=supersecret123 \
  -v minio-data:/data \
  -v /path/to/certs:/root/.minio/certs \
  zonlykroks/minio:latest
```

Place your TLS certificates in the mounted certs directory:
- `public.crt` - TLS certificate
- `private.key` - TLS private key

## Tags

- `latest` - Latest stable release
- `RELEASE.2025-10-15T17-29-55Z` - Specific release tag

## Example Docker Compose

```yaml
services:
  minio:
    image: zonlykroks/minio:latest
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: supersecret123
      MINIO_BROWSER: "on"
    volumes:
      - minio-data:/data
    healthcheck:
      test: ["CMD", "mc", "ready", "local", "--quiet"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

volumes:
  minio-data:
```

## Kubernetes Example

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: minio-credentials
type: Opaque
stringData:
  root-user: admin
  root-password: supersecret123
---
apiVersion: v1
kind: Service
metadata:
  name: minio
spec:
  ports:
    - name: api
      port: 9000
    - name: console
      port: 9001
  selector:
    app: minio
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: zonlykroks/minio:latest
        env:
        - name: MINIO_ROOT_USER
          valueFrom:
            secretKeyRef:
              name: minio-credentials
              key: root-user
        - name: MINIO_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: minio-credentials
              key: root-password
        ports:
        - containerPort: 9000
          name: api
        - containerPort: 9001
          name: console
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: minio-pvc
```

## Use Cases

- S3-compatible object storage for applications
- Backup and archival storage
- Machine learning dataset storage
- Media streaming and content delivery
- Data lake storage
- Kubernetes persistent volume storage

## Source & Support

- **Source Code**: https://github.com/zOnlyKroks/container-images
- **MinIO Upstream**: https://github.com/minio/minio
- **MinIO Documentation**: https://min.io/docs/minio/
- **Issues**: https://github.com/zOnlyKroks/container-images/issues
- **License**: AGPL-3.0

## Notes

- MinIO will NOT start without credentials - always set `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`
- Minimum password length is 8 characters
- For production use, always use TLS/SSL encryption
- Consider using distributed mode for high availability
- Use file-based credentials (secrets) in production environments
- Single-node deployments are suitable for development and testing only

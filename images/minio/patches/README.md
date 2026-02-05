# MinIO Security Patches

This directory contains security patches applied to the MinIO source code in the **hardened** image variant.

## Overview

- **Vanilla images**: Built straight from official MinIO source without modifications
- **Hardened images**: Built from official MinIO source with security patches applied (this directory)

## How to Create Patches

Patches are applied using the standard `patch` utility with `-p1` flag. Follow these steps to create patches:

### 1. Clone the MinIO Repository

```bash
git clone --branch RELEASE.2025-10-15T17-29-55Z https://github.com/minio/minio.git
cd minio
```

### 2. Make Your Security Fixes

Edit the source files to fix CVEs or security issues:

```bash
# Example: Fix a hypothetical security issue
vim cmd/server.go
```

### 3. Generate the Patch File

```bash
# Create a patch file showing your changes
git diff > ../0001-fix-cve-xxxx-xxxx.patch
```

### 4. Add Patch to This Directory

Copy your patch file to this directory with a descriptive name:

```bash
cp ../0001-fix-cve-xxxx-xxxx.patch images/minio/patches/
```

## Patch Naming Convention

Use descriptive names that include:
- Sequential number (0001, 0002, etc.)
- CVE number or issue description
- `.patch` extension

Examples:
- `0001-fix-cve-2024-12345-auth-bypass.patch`
- `0002-fix-cve-2024-67890-path-traversal.patch`
- `0003-harden-tls-configuration.patch`

## Patch Format

Patches should be in unified diff format (created with `git diff` or `diff -u`):

```patch
diff --git a/cmd/server.go b/cmd/server.go
index 1234567..abcdefg 100644
--- a/cmd/server.go
+++ b/cmd/server.go
@@ -100,7 +100,7 @@ func startServer() {
     // Your changes here
-    oldCode()
+    newSecureCode()
 }
```

## Testing Patches

Before committing patches, test that they apply cleanly:

```bash
# Test patch application
cd minio
patch -p1 --dry-run < ../patches/0001-your-patch.patch

# If successful, apply it
patch -p1 < ../patches/0001-your-patch.patch

# Verify the build works
go build .
```

## Updating Patches for New Releases

When updating the MinIO version in `config.yaml`:

1. Test that existing patches still apply to the new version
2. Regenerate patches if conflicts occur
3. Document any changes in patch files

## Documentation

For each patch, consider adding comments in the patch file header explaining:
- What CVE or security issue it fixes
- Why the fix is necessary
- Any upstream tracking (GitHub issues, CVE database links)

Example header:

```patch
# Fix CVE-2024-12345: Authentication Bypass
# https://nvd.nist.gov/vuln/detail/CVE-2024-12345
# Upstream issue: https://github.com/minio/minio/issues/12345
#
# This patch adds proper validation to prevent authentication bypass
# when using malformed JWT tokens.

diff --git a/cmd/auth.go b/cmd/auth.go
...
```

## Build Process

The hardened Dockerfile (`Dockerfile.hardened`) will automatically:
1. Clone the MinIO source at the specified release tag
2. Apply all `*.patch` files from this directory in alphabetical order
3. Build the patched source
4. Create the container image with `-hardened` suffix

## No Patches?

If this directory is empty (no `.patch` files), the hardened build will proceed with a warning but will still build successfully using vanilla source. This allows the build infrastructure to remain in place even when no patches are currently needed.

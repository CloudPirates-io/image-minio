#!/bin/bash
set -euo pipefail

# Script to reset MinIO source and apply all patches
# This makes it easier to create new patches on top of existing ones

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINIO_DIR="$SCRIPT_DIR/minio"

cd "$MINIO_DIR"

echo "===================================="
echo "MinIO Patch Application Script"
echo "===================================="
echo

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "❌ Error: $MINIO_DIR is not a git repository"
    echo "Please run: git clone --depth 1 --branch RELEASE.2025-10-15T17-29-55Z https://github.com/minio/minio.git"
    exit 1
fi

# Reset to clean state
echo "🔄 Resetting to clean state..."
git reset --hard HEAD
git clean -fd

echo "✅ Repository reset to clean state"
echo

# Find all patch files
PATCH_FILES=("$SCRIPT_DIR"/*.patch)

if [ ${#PATCH_FILES[@]} -eq 0 ] || [ ! -f "${PATCH_FILES[0]}" ]; then
    echo "⚠️  No patch files found in $SCRIPT_DIR"
    echo "Current state: Clean MinIO source (no patches applied)"
    exit 0
fi

# Apply patches in order
echo "📋 Found ${#PATCH_FILES[@]} patch file(s)"
echo

for patch_file in "${PATCH_FILES[@]}"; do
    if [ -f "$patch_file" ]; then
        patch_name=$(basename "$patch_file")
        echo "🔧 Applying: $patch_name"

        if patch -p1 < "$patch_file"; then
            echo "   ✅ Applied successfully"
        else
            echo "   ❌ Failed to apply patch"
            exit 1
        fi
        echo
    fi
done

echo "===================================="
echo "✅ All patches applied successfully!"
echo "===================================="
echo
echo "Current state:"
echo "  - Working directory: $MINIO_DIR"
echo "  - All patches have been applied"
echo "  - Ready to create new patches with:"
echo "      go get <package>@<version>"
echo "      go mod tidy"
echo "      git diff go.mod go.sum > ../NNNN-description.patch"
echo

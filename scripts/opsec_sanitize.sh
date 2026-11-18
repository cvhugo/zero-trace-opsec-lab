#!/usr/bin/env bash
# ==============================================================================
# Name: opsec_sanitize.sh
# Description: Automates metadata inspection, forensic stripping via MAT2, and
#              SHA-256 integrity verification prior to file publication.
# ==============================================================================

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <target_file_path>"
    exit 1
fi

TARGET_FILE="$1"

if [[ ! -f "$TARGET_FILE" ]]; then
    echo "[ERROR] File '$TARGET_FILE' does not exist."
    exit 1
fi

if ! command -v mat2 &> /dev/null; then
    echo "[ERROR] 'mat2' is not installed. Install it with: sudo apt install mat2"
    exit 1
fi

FILENAME=$(basename -- "$TARGET_FILE")
EXTENSION="${FILENAME##*.}"
BASENAME="${FILENAME%.*}"
DIRNAME=$(dirname -- "$TARGET_FILE")
CLEANED_FILE="${DIRNAME}/${BASENAME}.cleaned.${EXTENSION}"

echo "============================================================"
echo " OPSEC FORENSIC AUDIT & SANITIZATION - $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo "============================================================"
echo "[1/4] Original SHA-256 checksum:"
sha256sum "$TARGET_FILE"

echo -e "\n[2/4] Embedded metadata detected in source file:"
mat2 -s "$TARGET_FILE" || true

echo -e "\n[3/4] Running forensic sanitization..."
mat2 "$TARGET_FILE"

if [[ ! -f "$CLEANED_FILE" ]]; then
    echo "[ERROR] Expected sanitized output file was not generated."
    exit 1
fi

echo -e "\n[4/4] Verifying zero residual metadata and computing new SHA-256 checksum:"
mat2 -s "$CLEANED_FILE"
sha256sum "$CLEANED_FILE"
echo "============================================================"
echo " Sanitization complete. Clean artifact ready: $CLEANED_FILE"
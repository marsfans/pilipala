#!/usr/bin/env bash
# 辅助打包脚本（如果需要单独打包）
set -euo pipefail
if [ $# -lt 2 ]; then
  echo "Usage: $0 <source-dir> <out-name>"
  exit 1
fi
SRC="$1"
OUTNAME="$2"
tar czf "${OUTNAME}.tar.gz" -C "$(dirname "$SRC")" "$(basename "$SRC")"
echo "Created ${OUTNAME}.tar.gz"

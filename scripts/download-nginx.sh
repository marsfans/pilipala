#!/usr/bin/env bash
set -euo pipefail

if [ -z "${NGINX_VERSION:-}" ]; then
  echo "NGINX_VERSION must be set"
  exit 1
fi

TGZ="nginx-${NGINX_VERSION}.tar.gz"
URL="http://nginx.org/download/${TGZ}"

mkdir -p build
cd build

if [ ! -f "${TGZ}" ]; then
  echo "Downloading ${URL}"
  curl -fsSL -O "${URL}"
else
  echo "${TGZ} already exists"
fi

# Extract
if [ ! -d "nginx-${NGINX_VERSION}" ]; then
  tar xzf "${TGZ}"
fi

echo "Source available at $(pwd)/nginx-${NGINX_VERSION}"

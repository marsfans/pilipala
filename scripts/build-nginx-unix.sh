#!/usr/bin/env bash
set -euo pipefail

OS="${1:-linux}"  # "linux" or "macos"
NGINX_VERSION="${NGINX_VERSION:-}"
WORKDIR="$(pwd)"
ARCH="$(uname -m)"
DISTDIR="${WORKDIR}/dist"
mkdir -p "${DISTDIR}"

if [ -z "${NGINX_VERSION}" ]; then
  echo "Please set NGINX_VERSION env var"
  exit 1
fi

# Download source
bash scripts/download-nginx.sh

cd "build/nginx-${NGINX_VERSION}"

# Download and prepare static dependencies (PCRE, zlib, OpenSSL)
mkdir -p build-deps
cd build-deps

# PCRE
# wget -c https://ftp.pcre.org/pub/pcre/pcre-8.45.tar.gz
# tar xf pcre-8.45.tar.gz
git clone https://github.com/PCRE2Project/pcre2
PCRE_DIR=$(pwd)/pcre2

# zlib
# wget -c https://zlib.net/zlib-1.2.13.tar.gz
# tar xf zlib-1.2.13.tar.gz
git clone https://github.com/zlib-ng/zlib-ng
ZLIB_DIR=$(pwd)/zlib-ng

# OpenSSL
# wget -c https://www.openssl.org/source/openssl-3.1.4.tar.gz
# tar xf openssl-3.1.4.tar.gz
git clone https://github.com/openssl/openssl
OPENSSL_DIR=$(pwd)/openssl
cd ..

# Install build deps on Linux; on macOS assume Homebrew environment exists on runner
if [ "${OS}" = "linux" ]; then
  echo "Installing build deps (linux)..."
  sudo apt-get update -y
  sudo apt-get install -y build-essential wget tar make gcc
elif [ "${OS}" = "macos" ]; then
  echo "macOS runner: make sure dependencies (openssl, pcre) are available."
fi

# configure with static linking
./configure \
  --prefix=/usr/local/nginx \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-pcre=${PCRE_DIR} \
  --with-zlib=${ZLIB_DIR} \
  --with-openssl=${OPENSSL_DIR} \
  # --with-file-aio \
  # --with-threads \
  --with-cc-opt='-static' \
  --with-ld-opt='-static'

# build
make -j$(nproc || sysctl -n hw.ncpu || echo 2)
if command -v strip >/dev/null 2>&1; then
  strip objs/nginx || true
fi

# package
OUTNAME="nginx-${NGINX_VERSION}-${OS}-${ARCH}-static"
OUTDIR="${WORKDIR}/dist"
mkdir -p "${OUTDIR}/${OUTNAME}"
make install DESTDIR="${OUTDIR}/${OUTNAME}"

cd "${OUTDIR}"
tar czf "${OUTNAME}.tar.gz" "${OUTNAME}"

echo "Packaged: ${OUTDIR}/${OUTNAME}.tar.gz"
ls -lh "${OUTDIR}/${OUTNAME}.tar.gz"

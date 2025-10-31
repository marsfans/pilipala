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

# Install build deps on Linux; on macOS assume Homebrew environment exists on runner
if [ "${OS}" = "linux" ]; then
  echo "Installing build deps (linux)..."
  sudo apt-get update -y
  sudo apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g-dev libssl-dev ca-certificates wget tar
elif [ "${OS}" = "macos" ]; then
  echo "macOS runner: make sure dependencies (openssl, pcre) are available."
  # macOS runners already include many things; use /usr/local/opt/openssl if needed
fi

# configure options (adjust as required)
# link statically to pcre/openssl if desired, or use system libs
./configure \
  --prefix=/usr/local/nginx \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-pcre \
  --with-file-aio \
  --with-threads

# build
make -j$(nproc || sysctl -n hw.ncpu || echo 2)
# strip binaries to reduce size if available
if command -v strip >/dev/null 2>&1; then
  strip objs/nginx || true
fi

# package
OUTNAME="nginx-${NGINX_VERSION}-${OS}-${ARCH}"
OUTDIR="${WORKDIR}/dist"
mkdir -p "${OUTDIR}/${OUTNAME}"
mkdir -p "${OUTDIR}"

# install to temporary dir
make install DESTDIR="${OUTDIR}/${OUTNAME}"

# create tarball
cd "${OUTDIR}"
tar czf "${OUTNAME}.tar.gz" "${OUTNAME}"

echo "Packaged: ${OUTDIR}/${OUTNAME}.tar.gz"
ls -lh "${OUTDIR}/${OUTNAME}.tar.gz"

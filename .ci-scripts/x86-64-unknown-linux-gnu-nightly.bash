#!/bin/bash

set -e

API_KEY=$1
if [[ ${API_KEY} == "" ]]
then
  echo "API_KEY needs to be supplied as first script argument."
  exit 1
fi

TODAY=$(date +%Y%m%d)

# Compiler target parameters
ARCH=x86-64

# Triple construction
VENDOR=unknown
OS=linux-gnu
TRIPLE=${ARCH}-${VENDOR}-${OS}

# Build parameters
BUILD_PREFIX=$(mktemp -d)
STABLE_VERSION="nightly-${TODAY}"
BUILD_DIR=${BUILD_PREFIX}/${STABLE_VERSION}

# Asset information
PACKAGE_DIR=$(mktemp -d)
PACKAGE=stable-${TRIPLE}

# Cloudsmith configuration
CLOUDSMITH_VERSION=${TODAY}
ASSET_OWNER=main-pony
ASSET_REPO=pony-nightlies
ASSET_PATH=${ASSET_OWNER}/${ASSET_REPO}
ASSET_FILE=${PACKAGE_DIR}/${PACKAGE}.tar.gz
ASSET_SUMMARY="Pony dependency manager"
ASSET_DESCRIPTION="https://github.com/ponylang/pony-stable"

# Build stable installation
echo "Building stable..."
make install prefix=${BUILD_DIR} arch=${ARCH} version="${STABLE_VERSION}"

# Package it all up
echo "Creating .tar.gz of stable..."
pushd ${BUILD_PREFIX} || exit 1
tar -cvzf ${ASSET_FILE} *
popd || exit 1

# Ship it off to cloudsmith
echo "Uploading package to cloudsmith..."
cloudsmith push raw --version "${CLOUDSMITH_VERSION}" --api-key ${API_KEY} \
  --summary "${ASSET_SUMMARY}" --description "${ASSET_DESCRIPTION}" \
  ${ASSET_PATH} ${ASSET_FILE}

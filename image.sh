#!/usr/bin/env bash
# Image de développement et de CI (Dockerfile), une par architecture :
#   ./image.sh tag   <amd64|arm64>           étiquette complète (ghcr.io/mipac/devimages:...)
#   ./image.sh build <amd64|arm64> [--push]  construit (chargée localement, ou publiée)
# Étiquette : <arch>-ubuntu<version>-<mkl|armpl><version>-cuda<version>, versions de versions.sh.
# amd64 sur un poste arm64 (ou l'inverse) : construite sous émulation (Mac : Rosetta), lent mais identique.
# Publication : gh auth token | docker login ghcr.io -u mipac --password-stdin (jeton write:packages).
set -euo pipefail
cd "$(dirname "$0")"
. ./versions.sh
IMAGE=ghcr.io/mipac/devimages

usage() { sed -n '2,7p' "$0" | sed 's/^# \?//' >&2; exit 1; }
[ $# -ge 2 ] || usage
cmd=$1 arch=$2

case $arch in
  amd64) cpulib="mkl$MKL_VERSION" ;;
  arm64) cpulib="armpl$ARMPL_VERSION" ;;
  *) usage ;;
esac
tag="$IMAGE:$arch-ubuntu$UBUNTU_VERSION-$cpulib-cuda$CUDA_VERSION"

case $cmd in
  tag) echo "$tag" ;;
  build)
    out=--load
    if [ "${3:-}" = --push ]; then out=--push; fi
    docker buildx build --platform "linux/$arch" $out -t "$tag" \
      --build-arg "UBUNTU_VERSION=$UBUNTU_VERSION" \
      --label "org.opencontainers.image.source=https://github.com/mipac/devimages" \
      .
    echo "$tag"
    ;;
  *) usage ;;
esac

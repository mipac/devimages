#!/usr/bin/env bash
# Installe Intel oneMKL (partie minimale : bibliothèques, en-têtes C, MKLConfig.cmake) depuis le dépôt apt
# d'Intel, dans /opt/intel/oneapi ; version MKL_VERSION de versions.sh. Bibliothèques statiques supprimées (~0,9 Go) :
# liaison dynamique seulement (CMake : MKL_LINK dynamic). Utilisé par l'image (Dockerfile). Ubuntu / Debian ; demande root (ou sudo). Sur aarch64 (MKL n'existe que pour x86-64) : installe ARM PL à
# la place (armpl.sh).
set -euo pipefail
if [ "$(uname -m)" = "aarch64" ]; then
  echo "aarch64 : pas de oneMKL, ARM PL à la place"
  exec "$(dirname "$0")/armpl.sh"
fi
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
. "$(dirname "$0")/../versions.sh"
if [ -f "/opt/intel/oneapi/mkl/$MKL_VERSION/lib/cmake/mkl/MKLConfig.cmake" ]; then
  echo "oneMKL $MKL_VERSION déjà installé"
  exit 0
fi
export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
  | gpg --dearmor | $SUDO tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
  | $SUDO tee /etc/apt/sources.list.d/oneAPI.list > /dev/null
$SUDO apt-get update -qq -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/oneAPI.list -o Dir::Etc::sourceparts=-
$SUDO apt-get install -y -qq --no-install-recommends "intel-oneapi-mkl-core-devel-$MKL_VERSION"
$SUDO find "/opt/intel/oneapi/mkl/$MKL_VERSION/lib" -name '*.a' -delete
ls "/opt/intel/oneapi/mkl/$MKL_VERSION/lib/cmake/mkl/MKLConfig.cmake"

#!/usr/bin/env bash
# Installe Arm Performance Libraries (BLAS, LAPACK, FFT ; ILP64 séquentiel : libarmpl_ilp64) depuis le dépôt apt
# d'Arm, dans /opt/arm/arm-performance-libraries. Remplace oneMKL sur aarch64 (MKL n'existe que pour x86-64) ;
# appelé par mkl.sh sur cette architecture. Ubuntu / Debian ; demande root (ou sudo). Version
# ARMPL_VERSION de versions.sh. Variantes séquentielles gardées (libarmpl_ilp64, libarmpl_lp64 : dynamiques, ne
# dépendent que de la libc) ; variantes OpenMP (_mp), bibliothèques statiques et exemples supprimés (~0,5 Go).
# Dépôt « arm-toolchains » (clé du 2026-07-03, publiée à sa racine) : mêmes chemins de liste et de clé que le paquet
# arm-toolchains-repository qu'ARM PL tire en dépendance, qui les reprend donc sans conflit. Ne pas utiliser
# l'ancien dépôt (arm-toolchains:ubuntu-24/noble) : son paquet arm-toolchains-transition installe une clé périmée
# (NO_PUBKEY 8144CA1611A0BD71, apt-get update échoue ensuite).
set -euo pipefail
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
if [ "$(uname -m)" != "aarch64" ]; then
  echo "ARM PL : aarch64 seulement (architecture : $(uname -m))" >&2
  exit 1
fi
. "$(dirname "$0")/../versions.sh"
if dpkg-query -W -f='${Version}' arm-performance-libraries 2>/dev/null | grep -q "^$ARMPL_VERSION-"; then
  echo "ARM PL $ARMPL_VERSION déjà installé"
  exit 0
fi
export DEBIAN_FRONTEND=noninteractive
. /etc/os-release
REPO=https://developer.arm.com/packages/arm-toolchains
LIST=/etc/apt/sources.list.d/arm-toolchains.list
curl -fsSL "$REPO/arm-toolchains.gpg" | $SUDO tee /usr/share/keyrings/arm-toolchains.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/arm-toolchains.gpg] $REPO/$ID $VERSION_CODENAME main" | $SUDO tee "$LIST" > /dev/null
$SUDO apt-get update -qq -o Dir::Etc::sourcelist="$LIST" -o Dir::Etc::sourceparts=-
$SUDO apt-get install -y -qq --no-install-recommends -o Dpkg::Options::=--force-confold \
  "arm-performance-libraries=$ARMPL_VERSION-*"
lib=/opt/arm/arm-performance-libraries/lib
$SUDO rm -f "$lib"/libarmpl_*_mp.so*
$SUDO find -L /opt/arm/arm-performance-libraries/ -name '*.a' -delete
$SUDO rm -rf /opt/arm/arm-performance-libraries/examples*
$SUDO find "$lib" -xtype l -delete
ls /opt/arm/arm-performance-libraries/lib/libarmpl_ilp64.so

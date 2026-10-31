#!/usr/bin/env bash
# Installe les outils de développement depuis les paquets Ubuntu : GoogleTest (libgtest-dev), fmt (libfmt-dev),
# gcovr (rapport de couverture), clang-format, gh (GitHub CLI ; authentification une fois par « gh auth login »).
# Utilisé par l'image (Dockerfile). Demande root (ou sudo).
set -euo pipefail
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
if ls /usr/lib/*/cmake/GTest/GTestConfig.cmake > /dev/null 2>&1 && [ -f /usr/include/fmt/format.h ] \
  && command -v gcovr > /dev/null 2>&1 && command -v clang-format > /dev/null 2>&1 \
  && command -v gh > /dev/null 2>&1; then
  echo "outils de développement déjà installés"
  exit 0
fi
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -qq
$SUDO apt-get install -y -qq --no-install-recommends libgtest-dev libfmt-dev gcovr clang-format gh

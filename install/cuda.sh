#!/usr/bin/env bash
# Installe CUDA (nvcc, cudart, cuBLAS, cuFFT, cuSOLVER ; preset gpu-*, compilé par nvcc même sans GPU) depuis le
# dépôt apt de NVIDIA (x86_64, ou sbsa sur aarch64 : Grace, DGX Spark), version CUDA_VERSION de versions.sh,
# dans /usr/local/cuda-<version> (lien /usr/local/cuda ; ajouter /usr/local/cuda/bin au PATH). Paquets séparés,
# sans pilote (le NVIDIA Container Toolkit apporte celui de l'hôte) ; bibliothèques statiques des bibliothèques
# supprimées (~2 Go ; liaison dynamique : CMake CUDA::cublas...), sauf cudart et cudadevrt que nvcc lie par
# défaut. Utilisé par l'image (Dockerfile). Ubuntu ; demande root (ou sudo).
set -euo pipefail
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
. "$(dirname "$0")/../versions.sh"
prefix="/usr/local/cuda-$CUDA_VERSION"
if [ -x "$prefix/bin/nvcc" ]; then
  echo "CUDA $CUDA_VERSION déjà installé"
  exit 0
fi
case "$(uname -m)" in
  x86_64) arch=x86_64 ;;
  aarch64) arch=sbsa ;;
  *) echo "CUDA : architecture non prise en charge : $(uname -m)" >&2; exit 1 ;;
esac
export DEBIAN_FRONTEND=noninteractive
repo="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION//./}/$arch"
tmp=$(mktemp -d)
curl -fsSL -o "$tmp/cuda-keyring.deb" "$repo/cuda-keyring_1.1-1_all.deb"
$SUDO dpkg -i "$tmp/cuda-keyring.deb"
rm -rf "$tmp"
$SUDO apt-get update -qq
v=${CUDA_VERSION//./-}
# libcusparse et libnvjitlink : requises par libcusolver.so à l'édition de liens, mais non déclarées par son paquet
$SUDO apt-get install -y -qq --no-install-recommends \
  "cuda-nvcc-$v" "cuda-cudart-dev-$v" "libcublas-dev-$v" "libcufft-dev-$v" "libcusolver-dev-$v" \
  "libcusparse-$v" "libnvjitlink-$v"
$SUDO find "$prefix/" -name '*_static*.a' ! -name 'libcudart_static.a' -delete
# Sans GPU (CI) : pilote factice de CUDA (toutes ses fonctions : « pas de pilote »), pour charger les exécutables liés
# à libcuda (API driver) ; hors du chemin par défaut, activé par LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs.
# Jamais dans le chemin par défaut : il masquerait le pilote de l'hôte (NVIDIA Container Toolkit).
$SUDO ln -sf libcuda.so "$prefix/lib64/stubs/libcuda.so.1"
"$prefix/bin/nvcc" --version | tail -1

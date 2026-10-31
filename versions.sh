# Versions épinglées des dépendances de l'image (lu par install/*.sh et image.sh). Seule source de vérité : elles
# composent l'étiquette de l'image (<arch>-ubuntu<UBUNTU>-<mkl|armpl><version>-cuda<version>), donc changer une
# version = nouvelle étiquette, à reporter dans les projets qui l'utilisent (devcontainers, CI).
UBUNTU_VERSION=24.04
# oneMKL (x86-64) : paquet intel-oneapi-mkl-core-devel-<version> du dépôt apt d'Intel
MKL_VERSION=2026.2
# ARM PL (aarch64) : paquet arm-performance-libraries du dépôt apt d'Arm (version amont, sans révision)
ARMPL_VERSION=26.07.0
# CUDA : paquets cuda-nvcc-<x-y>, libcublas-dev-<x-y>... du dépôt apt de NVIDIA (x86_64 et sbsa)
CUDA_VERSION=12.9

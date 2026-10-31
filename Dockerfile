# Image de développement et de CI commune aux projets, une par architecture (pas de manifeste multi-architecture) :
#   amd64 : oneMKL + CUDA ;  arm64 : ARM PL + CUDA (dépôt sbsa de NVIDIA : Grace, DGX Spark).
# Construite et publiée par image.sh sur ghcr.io/mipac/devimages, étiquette
# <arch>-ubuntu<version>-<mkl|armpl><version>-cuda<version> (versions.sh). Les scripts install/*.sh sont la seule
# source de vérité des dépendances et de leurs dépôts apt (clés téléchargées à l'installation, pas versionnées : elles
# expirent ou changent).
# Une couche par script, de la plus stable à la plus changeante ; les outils de développement (couche qui change le
# plus) en dernier, pour ne pas reconstruire les bibliothèques ni CUDA quand ils changent.
# Base Ubuntu nue (pas l'image devcontainers de Microsoft : ~0,6 Go d'outils inutiles en CI) ; le confort des
# devcontainers (zsh...) est ajouté par leurs features, sur le poste seulement.
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

# Base de compilation : build-essential, cmake, python3 ; git, curl, sudo ; nodejs : les actions JavaScript
# (actions/checkout...) s'exécutent dans le container du job sous Forgejo. Utilisateur vscode (uid 1000, sudo sans
# mot de passe) à la place de ubuntu.
RUN apt-get update -qq \
    && apt-get install -y -qq --no-install-recommends build-essential cmake python3 git curl ca-certificates \
       gnupg sudo nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && userdel -r ubuntu \
    && useradd -m -u 1000 -s /bin/bash vscode \
    && echo 'vscode ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vscode

# Bibliothèques CPU : oneMKL (amd64) ou ARM PL (arm64), choisies par mkl.sh selon l'architecture.
COPY versions.sh /tmp/devimages/
COPY install/mkl.sh install/armpl.sh /tmp/devimages/install/
RUN bash /tmp/devimages/install/mkl.sh && rm -rf /var/lib/apt/lists/* /tmp/devimages

# CUDA (nvcc, cuBLAS, cuFFT, cuSOLVER). Sans GPU : LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs (cuda.sh).
COPY versions.sh /tmp/devimages/
COPY install/cuda.sh /tmp/devimages/install/
RUN bash /tmp/devimages/install/cuda.sh && rm -rf /var/lib/apt/lists/* /tmp/devimages
ENV PATH=/usr/local/cuda/bin:${PATH}

# Outils de développement : GoogleTest, fmt, gcovr, clang-format, gh.
COPY install/dev_tools.sh /tmp/devimages/install/
RUN bash /tmp/devimages/install/dev_tools.sh && rm -rf /var/lib/apt/lists/* /tmp/devimages

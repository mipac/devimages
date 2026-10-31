# devimages

Images de développement et de CI communes aux projets : une par architecture, bibliothèques CPU + CUDA.

| Image | Contenu |
|---|---|
| `ghcr.io/mipac/devimages:amd64-ubuntu24.04-mkl2026.2-cuda12.9` | Ubuntu 24.04, oneMKL 2026.2, CUDA 12.9 |
| `ghcr.io/mipac/devimages:arm64-ubuntu24.04-armpl26.07.0-cuda12.9` | Ubuntu 24.04, ARM PL 26.07.0, CUDA 12.9 (sbsa : Grace, DGX Spark) |

Étiquette : `<arch>-ubuntu<v>-<mkl|armpl><v>-cuda<v>`, toutes les versions dedans : une étiquette ne change jamais
de contenu (hors outils de développement). Paquet privé : `docker login ghcr.io` (jeton `read:packages`) pour tirer.

## Contenu

- Base `ubuntu` nue : build-essential, cmake, python3, git, curl, sudo, nodejs (actions de la CI Forgejo) ;
  utilisateur `vscode` (uid 1000, sudo sans mot de passe).
- `install/mkl.sh` (amd64) : `intel-oneapi-mkl-core-devel-<v>`, sans bibliothèques statiques.
- `install/armpl.sh` (arm64) : `arm-performance-libraries`, variantes séquentielles `ilp64` et `lp64`
  seulement (ni OpenMP, ni statiques, ni exemples).
- `install/cuda.sh` : dépôt apt de NVIDIA (`x86_64` / `sbsa`), paquets séparés : nvcc, cudart, cuBLAS, cuFFT,
  cuSOLVER (+ cuSPARSE, nvJitLink requis par cuSOLVER). Sans pilote (le NVIDIA Container Toolkit apporte celui de
  l'hôte), sans bibliothèques statiques sauf `cudart` / `cudadevrt`. `/usr/local/cuda/bin` dans le `PATH`.
- `install/dev_tools.sh` : GoogleTest, fmt, gcovr, clang-format, gh.

Liaison dynamique uniquement (MKL : `MKL_LINK dynamic` ; CUDA : `CUDA::cublas`, pas `cublas_static`).

**Sans GPU** (CI, Mac) : les exécutables liés à `libcuda` (API driver) ne se chargent pas sans pilote. Le pilote
factice de CUDA est prêt hors du chemin par défaut :

```sh
LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs ctest ...   # toutes les fonctions driver : « pas de pilote »
```

Ne jamais le mettre dans le chemin par défaut : sur une machine avec GPU, il masquerait le vrai pilote.

## Construire et publier

```sh
./image.sh tag amd64                 # étiquette
./image.sh build arm64               # build local (chargée dans docker)
gh auth token | docker login ghcr.io -u mipac --password-stdin   # jeton avec write:packages
./image.sh build arm64 --push
./image.sh build amd64 --push        # sur Mac : sous Rosetta, ~10 min
```

## Changer une version

1. Modifier `versions.sh` (MKL, ARM PL, CUDA, Ubuntu).
2. `./image.sh build <arch> --push` pour les deux architectures : nouvelle étiquette, l'ancienne reste.
3. Reporter l'étiquette dans les projets (devcontainers, CI).

## Limites connues

- amd64 émulé sur Mac (Rosetta) : GCC plante en LTO avec éditions de liens parallèles (`lto1: internal compiler
  error` dans `return_token`, jobserver) ; désactiver LTO sur ces builds. Pas de problème en x86-64 natif.

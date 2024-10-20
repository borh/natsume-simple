{
  pkgs,
  lib,
  config,
  ...
}: let
  #cudaSupport = false;
  #cudaVersion = "12.4";
  #cuda-common-redist = with pkgs.cudaPackages; [
  #  cuda_cccl # cub/cub.cuh
  #  libcublas # cublas_v2.h
  #  libcurand # curand.h
  #  libcusparse # cusparse.h
  #  libcufft # cufft.h
  #  cudnn # cudnn.h
  #];
  #cuda-native-redist = pkgs.symlinkJoin {
  #  name = "cuda-native-redist-${cudaVersion}";
  #  paths = with pkgs.cudaPackages;
  #    [
  #      cuda_cudart # cuda_runtime.h cuda_runtime_api.h
  #      cuda_nvcc
  #      cuda_nvtx
  #      cuda_cupti
  #      cuda_nvrtc
  #      libcusolver
  #      nccl
  #      pkgs.linuxPackages_latest.nvidia_x11
  #    ]
  #    ++ cuda-common-redist;
  #};
  #cuda-redist = pkgs.symlinkJoin {
  #  name = "cuda-redist-${cudaVersion}";
  #  paths = cuda-native-redist;
  #};
  #rocmSupport = false;
  #rocmtoolkit_joined = pkgs.symlinkJoin {
  #  name = "rocm-merged";
  #  paths = with pkgs.rocmPackages; [
  #    rocm-core
  #    clr
  #    rccl
  #    miopen
  #    miopengemm
  #    rocrand
  #    rocblas
  #    rocsparse
  #    hipsparse
  #    rocthrust
  #    rocprim
  #    hipcub
  #    roctracer
  #    rocfft
  #    rocsolver
  #    hipfft
  #    hipsolver
  #    hipblas
  #    rocminfo
  #    rocm-thunk
  #    rocm-comgr
  #    rocm-device-libs
  #    rocm-runtime
  #    clr.icd
  #    hipify
  #  ];
  #  # Fix `setuptools` not being found
  #  postBuild = ''
  #    rm -rf $out/nix-support
  #  '';
  #};
  native-deps = with pkgs; [
    stdenv.cc.cc
    zlib
    gcc-unwrapped.lib
    stdenv
    stdenv.cc
    binutils
  ];
in
  # lib.attrsets.recursiveUpdate
  {
    # https://devenv.sh/basics/

    # https://devenv.sh/packages/
    packages =
      native-deps
      # ++ lib.optionals cudaSupport [cuda-native-redist] ++ lib.optionals rocmSupport [rocmtoolkit_joined]
      ;

    # https://devenv.sh/scripts/

    enterShell = ''
      # poetry run python -m ipykernel install --user --name=devenv-$(basename $PWD)
      export AZURE_API_KEY=$(cat /run/agenix/azure-us-west3-openai-key)
      export AZURE_API_BASE=$(cat /run/agenix/azure-us-west3-openai-base)
      export AZURE_DEPLOYMENT_NAME=$(cat /run/agenix/azure-us-west3-deployment-name)
      export AZURE_API_VERSION="2024-02-15-preview"
      export OPENAI_API_VERSION="2024-02-15-preview"

      export AWS_ACCESS_KEY_ID=$(cat /run/agenix/aws-access-key-id)
      export AWS_SECRET_ACCESS_KEY=$(cat /run/agenix/aws-secret-access-key)
      export AWS_REGION_NAME=ap-northeast-1

      export LD_LIBRARY_PATH=${lib.makeLibraryPath config.packages}
    '';

    #     # https://devenv.sh/languages/
    #     languages.python = {
    #       enable = true;
    #       package = pkgs.python312;
    #       uv = {
    #         enable = true;
    #         activate.enable = true;
    #       };
    #     };

    languages.rust.enable = true;
    languages.cplusplus.enable = true;
    languages.javascript = {
      enable = true;
      npm.enable = true;
    };

    # https://devenv.sh/pre-commit-hooks/
    pre-commit.hooks.shellcheck.enable = true;
    pre-commit.hooks.black.enable = true;

    # https://devenv.sh/processes/
    # processes.ping.exec = "ping example.com";

    scripts.export-pip.exec = ''
      poetry export -f requirements.txt | sed "s/ ;.*//" | grep -v "\-\-hash=sha256" > requirements.txt
      poetry export --extras cuda -f requirements.txt | sed "s/ ;.*//" | grep -v "\-\-hash=sha256" > requirements-cuda.txt; echo "cupy-cuda12x" >> requirements-cuda.txt
      cat requirements.txt | grep -v spacy > requirements-apple-silicon.txt; echo "spacy[apple]" >> requirements-apple-silicon.txt
    '';

    # See full reference at https://devenv.sh/reference/options/
  }
# recursiveUpdate:
#(
#    if cudaSupport
#    then {
#      env.LD_LIBRARY_PATH = lib.makeLibraryPath ([cuda-redist] ++ native-deps);
#      env.CUDNN_HOME = cuda-redist;
#      env.CUDA_HOME = cuda-redist;
#      env.CUDA_PATH = cuda-redist;
#    }
#    else if rocmSupport
#    then {
#      env.CUPY_INSTALL_USE_HIP = "1";
#      env.ROCM_HOME = rocmtoolkit_joined;
#      env.HCC_AMDGPU_TARGET = "gfx1100";
#      env.LD_LIBRARY_PATH = lib.makeLibraryPath ([rocmtoolkit_joined] ++ native-deps);
#    }
#    else {}
#  )


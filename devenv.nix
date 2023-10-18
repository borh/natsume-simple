{ pkgs, lib, ... }:
let
  cudaSupport = true;
  cudaVersion = "12.2";
  cuda-common-redist = with pkgs.cudaPackages_12_2; [
    cuda_cccl # cub/cub.cuh
    libcublas # cublas_v2.h
    libcurand # curand.h
    libcusparse # cusparse.h
    libcufft # cufft.h
    pkgs.cudaPackages_12_1.cudnn # cudnn.h # no 12.2 version
  ];

  cuda-native-redist = pkgs.symlinkJoin {
    name = "cuda-native-redist-${cudaVersion}";
    paths = with pkgs.cudaPackages_12_2; [
      cuda_cudart # cuda_runtime.h cuda_runtime_api.h
      cuda_nvcc
      cuda_nvtx
      cuda_cupti
      cuda_nvrtc
      libcusolver
      nccl
      pkgs.linuxPackages_latest.nvidia_x11
    ] ++ cuda-common-redist;
  };

  cuda-redist = pkgs.symlinkJoin {
    name = "cuda-redist-${cudaVersion}";
    paths = cuda-common-redist;
  };
in
{
  # https://devenv.sh/basics/

  # https://devenv.sh/packages/
  packages = [ pkgs.stdenv.cc.cc pkgs.zlib ] ++ lib.optionals cudaSupport [ cuda-native-redist ];

  # https://devenv.sh/scripts/

  enterShell = ''
    poetry run python -m ipykernel install --user --name=devenv-$(basename $PWD)
  '';

  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    package = pkgs.python311.withPackages (ps: with ps; [
    ]);
    poetry.enable = true;
    poetry.activate.enable = true;
  };

  # https://devenv.sh/pre-commit-hooks/
  pre-commit.hooks.shellcheck.enable = true;
  pre-commit.hooks.black.enable = true;

  # https://devenv.sh/processes/
  # processes.ping.exec = "ping example.com";

  scripts.export-pip.exec = "poetry export -f requirements.txt | sed \"s/ ;.*//\" > requirements.txt; poetry export --extras cuda -f requirements.txt | sed \"s/ ;.*//\" > requirements-cuda.txt";

  env.LD_LD_LIBRARY_PATH = lib.makeLibraryPath [ cuda-redist ];
  env.CUDNN_HOME = "" + lib.optionals cudaSupport cuda-redist;
  env.CUDA_HOME = "" + lib.optionals cudaSupport cuda-redist;
  env.CUDA_PATH = "" + lib.optionals cudaSupport cuda-redist;

  # See full reference at https://devenv.sh/reference/options/
}

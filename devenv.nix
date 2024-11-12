{
  pkgs,
  lib,
  config,
  ...
}: let
  native-deps = with pkgs; [
    stdenv.cc.cc
    zlib
    gcc-unwrapped.lib
    stdenv
    stdenv.cc
    binutils
    uv
  ];
in {
  # https://devenv.sh/basics/

  # https://devenv.sh/packages/
  packages =
    native-deps;

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

    export VITE_API_URL="http://localhost:9999"
  '';

  enterTest = ''
    uv run ruff format --fix
    uv run ruff check
    uv run pytest
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

  dotenv.enable = true;
  devcontainer.enable = true;

  languages.javascript = {
    enable = true;
    npm.enable = true;
  };

  # https://devenv.sh/pre-commit-hooks/
  pre-commit.hooks.shellcheck.enable = true;
  pre-commit.hooks.ruff.enable = true;
  pre-commit.hooks.ruff-format.enable = true;
  pre-commit.hooks.mypy.enable = true;
  pre-commit.hooks.mypy.verbose = true;

  # https://devenv.sh/processes/
  processes.python-api-server.exec = "uv run --with fastapi --with polars fastapi dev src/natsume_simple/server.py";

  scripts.export-pip.exec = ''
  '';

  # See full reference at https://devenv.sh/reference/options/
}

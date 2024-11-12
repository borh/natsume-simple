{
  pkgs,
  lib,
  config,
  ...
}: let
  native-deps = with pkgs; [
    git
    # stdenv.cc.cc
    # zlib
    # gcc-unwrapped.lib
    # stdenv
    # stdenv.cc
    # binutils
  ];
in {
  # https://devenv.sh/basics/

  # https://devenv.sh/packages/
  packages = native-deps;

  # https://devenv.sh/scripts/

  enterShell = ''
    # poetry run python -m ipykernel install --user --name=devenv-$(basename $PWD)
    # export LD_LIBRARY_PATH=${lib.makeLibraryPath config.packages}
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
  # pre-commit.hooks.mypy.enable = true;

  # https://devenv.sh/processes/
  processes.python-api-server.exec = "uv run --with fastapi --with polars fastapi dev src/natsume_simple/server.py";

  scripts.export-pip.exec = ''
  '';

  # See full reference at https://devenv.sh/reference/options/
}

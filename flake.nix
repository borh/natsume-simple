{
  description = "natsume-simple nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    # process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    # services-flake.url = "github:juspay/services-flake";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix2container = {
    #   url = "github:nlewo/nix2container";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
        # inputs.process-compose-flake.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          lib,
          ...
        }:
        let
          runtime-packages = [
            pkgs.uv
            pkgs.nodejs
          ];
          development-packages = [
            pkgs.bashInteractive
            pkgs.git
            pkgs.git-cliff # Changelog generator
            pkgs.bun
            pkgs.wget
            pkgs.pandoc
            pkgs.sqlite
          ];
        in
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
          formatter = pkgs.nixfmt-rfc-style;
          pre-commit.settings.hooks = {
            nixfmt-rfc-style.enable = true;
            flake-checker.enable = true;
            ruff.enable = true;
            ruff-format.enable = true;
          };

          devShells = {
            default = pkgs.mkShell {
              nativeBuildInputs = development-packages ++ runtime-packages;
              shellHook =
                let
                  p = self'.packages;
                  e = pn: lib.getBin pn;
                  local-packages = map (pn: e pn) (
                    with p;
                    [
                      run-tests
                      lint
                      prepare-data
                      extract-patterns
                      build-frontend
                      dev-server
                      server
                      run-all
                    ]
                  );
                  path-string = (lib.concatStringsSep "/bin:" local-packages) + "/bin";
                in
                ''
                  ${config.pre-commit.installationScript}
                  # Resetting tty settings prevents issues after exiting the shell
                  ${pkgs.coreutils}/bin/stty sane
                  export TERM="xterm-256color"
                  export LANG="en_US.UTF-8"
                  export LC_ALL="en_US.UTF-8"
                  # Set up shell and prompt
                  export SHELL=${pkgs.bashInteractive}/bin/bash
                  export PS1='(uv) \[\e[34m\]\w\[\e[0m\] $(if [[ $? == 0 ]]; then echo -e "\[\e[32m\]"; else echo -e "\[\e[31m\]"; fi)#\[\e[0m\] '
                  # Add local packages to PATH if not already present
                  if [[ ":$PATH:" != *":${path-string}:"* ]]; then
                    PATH="${path-string}:$PATH"
                  fi
                  export PATH

                  # Set up Python and dependencies
                  ${config.packages.initial-setup}/bin/initial-setup

                  # Enter venv by default via bash (ignoring existing configs)
                  echo "Entering natsume-simple venv via uv..."
                  exec uv run ${pkgs.bashInteractive}/bin/bash --noprofile --norc
                '';
            };
            # TODO: Make backend, data, and frontend-specific devShells as well
          };

          packages.initial-setup = pkgs.writeShellApplication {
            name = "initial-setup";
            runtimeInputs = runtime-packages;
            text = ''
              export PYTHON_VERSION=3.12.7
              uv python install $PYTHON_VERSION
              uv python pin $PYTHON_VERSION
              uv sync --dev --extra backend
            '';
          };
          packages.run-tests = pkgs.writeShellApplication {
            name = "run-tests";
            runtimeInputs = runtime-packages;
            text = ''
              ${config.packages.initial-setup}/bin/initial-setup
              mkdir -p natsume-frontend/build # Ensure directory exists to not fail test
              uv run pytest
            '';
          };
          packages.lint = pkgs.writeShellApplication {
            name = "lint";
            runtimeInputs = runtime-packages;
            text = ''
              ${config.packages.initial-setup}/bin/initial-setup
              nix fmt flake.nix
              uv run ruff format
              uv run ruff check --fix --select I --output-format=github src notebooks tests
              ${pkgs.mypy}/bin/mypy --ignore-missing-imports src
            '';
          };
          packages.build-frontend = pkgs.writeShellApplication {
            name = "build-frontend";
            runtimeInputs = runtime-packages;
            text = ''
              ${config.packages.initial-setup}/bin/initial-setup
              cd natsume-frontend && npm i && npm run build && cd ..
            '';
          };
          packages.dev-server = pkgs.writeShellApplication {
            name = "dev-server";
            runtimeInputs = runtime-packages;
            text = ''
              ${config.packages.initial-setup}/bin/initial-setup
              ${config.packages.build-frontend}/bin/build-frontend
              uv run --with fastapi --with polars fastapi dev --host localhost src/natsume_simple/server.py
            '';
          };
          packages.server = pkgs.writeShellApplication {
            name = "server";
            runtimeInputs = runtime-packages;
            text = ''
              ${config.packages.initial-setup}/bin/initial-setup
              ${config.packages.build-frontend}/bin/build-frontend
              uv run --with fastapi --with polars fastapi run --host localhost src/natsume_simple/server.py
            '';
          };
          packages.prepare-data = pkgs.writeShellApplication {
            name = "prepare-data";
            runtimeInputs = runtime-packages;
            text = ''
              ${config.packages.initial-setup}/bin/initial-setup
              uv run python src/natsume_simple/data.py --prepare
              uv run python src/natsume_simple/data.py --load \
                  --jnlp-sample-size 3000 \
                  --ted-sample-size 30000
            '';
          };
          packages.extract-patterns = pkgs.writeShellApplication {
            name = "extract-patterns";
            runtimeInputs = runtime-packages;
            text = ''
              ${config.packages.initial-setup}/bin/initial-setup
              uv run python src/natsume_simple/pattern_extraction.py \
                  --input-file data/jnlp-corpus.txt \
                  --data-dir data \
                  --model ja_ginza \
                  --corpus-name "jnlp"

              uv run python src/natsume_simple/pattern_extraction.py \
                  --input-file data/ted-corpus.txt \
                  --data-dir data \
                  --model ja_ginza \
                  --corpus-name "ted"
            '';
          };
          packages.run-all = pkgs.writeShellApplication {
            name = "run-all";
            runtimeInputs = runtime-packages;
            text = ''
              ${config.packages.initial-setup}/bin/initial-setup
              ${config.packages.prepare-data}/bin/prepare-data
              ${config.packages.extract-patterns}/bin/extract-patterns
              ${config.packages.server}/bin/server
            '';
          };
          packages.default = config.packages.server;
        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}

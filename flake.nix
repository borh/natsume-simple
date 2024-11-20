{
  description = "natsume-simple nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
        inputs.process-compose-flake.flakeModule
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        runtime-packages = [
          pkgs.uv
          pkgs.nodejs
        ];
      in {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.
        formatter = pkgs.nixfmt-rfc-style;

        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs =
              [
                pkgs.bash
                pkgs.zsh
                pkgs.git
                pkgs.bun
                pkgs.wget
                pkgs.pandoc
                pkgs.sqlite
              ]
              ++ runtime-packages;
            shellHook = ''
              # Resetting tty settings prevents issues exiting the shell
              ${pkgs.coreutils}/bin/stty sane

              # Set up Python and dependencies
              ${config.packages.initial-setup}/bin/initial-setup

              # Enter venv by default via zsh (ignoring .zshrc)
              echo "Entering natsume-simple venv via uv..."
              export PROMPT='(uv) %F{blue}%~%f %(?.%F{green}.%F{red})%#%f '
              exec uv run ${pkgs.zsh}/bin/zsh -f
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
        packages.test = pkgs.writeShellApplication {
          name = "test";
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
            uvx ruff format
            uvx ruff check --output-format=github src notebooks tests
            ${pkgs.mypy}/bin/mypy --ignore-missing-imports src
          '';
        };
        packages.dev-server = pkgs.writeShellApplication {
          name = "dev-server";
          runtimeInputs = runtime-packages;
          text = ''
            ${config.packages.initial-setup}/bin/initial-setup
            cd natsume-frontend && npm i && npm run build && cd ..
            uv run --with fastapi --with polars fastapi dev --host localhost src/natsume_simple/server.py
          '';
        };
        packages.server = pkgs.writeShellApplication {
          name = "server";
          runtimeInputs = runtime-packages;
          text = ''
            ${config.packages.initial-setup}/bin/initial-setup
            cd natsume-frontend && npm i && npm run build && cd ..
            uv run --with fastapi --with polars fastapi run --host localhost src/natsume_simple/server.py
          '';
        };
        packages.prepare-data = pkgs.writeShellApplication {
          name = "prepare-data";
          runtimeInputs = runtime-packages;
          text = ''
            ${config.packages.initial-setup}/bin/initial-setup
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
            uv run python src/natsume_simple/pattern-extraction.py \
                --input-file data/jnlp-corpus.txt \
                --data-dir data \
                --model ja_ginza \
                --corpus-name "jnlp"

            uv run python src/natsume_simple/pattern-extraction.py \
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
        process-compose."natsume-simple-services" = {
          imports = [
            inputs.services-flake.processComposeModules.default
          ];
          # TODO: Add build and backend services
          # services = {
          #   api."api" = {
          #     enable = true;
          #   };
          # };
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}

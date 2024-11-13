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
                pkgs.bashInteractive
                pkgs.git
                pkgs.bun
                pkgs.wget
                pkgs.pandoc
                pkgs.sqlite
              ]
              ++ runtime-packages;
            shellHook = ''
              # Set up Python and dependencies
              ${config.packages.initial-setup}/bin/initial-setup

              # Enter venv by default
              exec uv run bash
            '';
          };
          # TODO: Make backend, data, and frontend-specific devShells as well
        };

        packages.initial-setup = pkgs.writeShellApplication {
          name = "initial-setup";
          runtimeInputs = runtime-packages;
          text = ''
            PYTHON_VERSION=3.12.7
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
            uv run pytest
          '';
        };
        packages.run-lint = pkgs.writeShellApplication {
          name = "run-lint";
          runtimeInputs = runtime-packages;
          text = ''
            ${config.packages.initial-setup}/bin/initial-setup
            uvx ruff format
            uvx ruff check --output-format=github src notebooks tests
            ${pkgs.mypy}/bin/mypy --ignore-missing-imports src
          '';
        };
        packages.run-server = pkgs.writeShellApplication {
          name = "run-server";
          runtimeInputs = runtime-packages;
          text = ''
            ${config.packages.initial-setup}/bin/initial-setup
            cd natsume-frontend && npm i && npm run build && cd ..
            uv run --with fastapi --with polars fastapi run --host localhost src/natsume_simple/server.py
          '';
        };
        packages.default = config.packages.run-server;
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

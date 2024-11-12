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
      }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;

        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.zsh
              pkgs.bash
              pkgs.git
              pkgs.nodejs
              pkgs.bun
              pkgs.wget
              pkgs.pandoc
              pkgs.sqlite
              pkgs.uv
            ];
            shellHook = ''
              # Set up Python and dependencies
              PYTHON_VERSION=3.12.7
              uv python install $PYTHON_VERSION
              uv python pin $PYTHON_VERSION
              uv sync --dev --extra backend

              # Enter venv by default
              touch ~/.zshrc
              exec uv run ${pkgs.zsh}/bin/zsh
            '';
          };
          # TODO: Make backend, data, and frontend-specific devShells as well
        };
        packages.default = pkgs.hello;
        process-compose."natsume-simple-services" = {
          imports = [
            inputs.services-flake.processComposeModules.default
          ];
          services = {
            # TODO: Add build and backend services
            api."api" = {
              enable = true;
            };
          };
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}

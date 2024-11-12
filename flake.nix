{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # nix-ld.url = "github:Mic92/nix-ld";
    # nix-ld.inputs.nixpkgs.follows = "nixpkgs";
    madness.url = "github:antithesishq/madness";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    nixpkgs-python.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys =
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  # nix-ld,
  outputs = { self, nixpkgs, devenv, systems, nixpkgs-unstable, ... }@inputs:
    let forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
        # graphviz = nixpkgs-unstable.packages.${system}.graphviz;
      });

      imports = [ inputs.madness.nixosModules.default ];

      devShells = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
        in {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [{
              packages = [ pkgs-unstable.graphviz ];

              languages.python = {
                enable = true;
                version = "3.12.6";
                manylinux = { enable = false; };
                # libraries = [ "${config.devenv.dotfile}/profile" ];
                # libraries = with pkgs; [ graphviz ];
                uv = {
                  enable = true;
                  package = pkgs-unstable.uv;
                  sync = { enable = true; };
                };
                # venv = {
                #   enable = true;
                #   requirements = ./requirements.lock;
                # };
              };

              # https://devenv.sh/processes/
              # processes.cargo-watch.exec = "cargo-watch";

              # https://devenv.sh/services/
              # services.postgres.enable = true;

              # export PATH="${config.devenv.dotfile}/profile/bin:$PATH"
              enterShell = ''
                uv venv
                source .devenv/state/venv/bin/activate
                uv pip install -r pyproject.toml
                unset LD_LIBRARY_PATH
              '';
              # export LD_LIBRARY_PATH=${lib.makeLibraryPath config.packages}
            }
            # nix-ld.nixosModules.nix-ld
            # inputs.madness.nixosModules.default

            # { programs.nix-ld.enable = true; }
              ];
          };
        });
    };
}

FROM nixos/nix

RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
RUN nix-channel --update

RUN nix-env -i git zsh cachix wget

# RUN nix --experimental-features "nix-command flakes" develop --command true

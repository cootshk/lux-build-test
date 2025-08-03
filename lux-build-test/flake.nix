{
    description = "Test for `lx build` in the nix store";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
        lux.url = "github:nvim-neorocks/lux";
    };
    outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
        flake-utils.lib.eachDefaultSystem (system:
        let 
            pkgs = import nixpkgs { inherit system; };
            lux = inputs.lux.packages.${system};
        in {
            devShells.default = pkgs.mkShell {
                buildInputs = with pkgs; [
                    luajit
                    lux.lux-cli
                    lux.lux-luajit
                    pkg-config
                ];
            };
        });
}
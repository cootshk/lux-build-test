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
            deps = with pkgs; [
                luajit
                lux.lux-cli
                lux.lux-luajit
                pkg-config
            ];
        in {
            devShells.default = pkgs.mkShell {
                buildInputs = deps;
            };
            packages.default = pkgs.stdenv.mkDerivation {
                pname = "lux-build-test";
                version = "0.1.0";
                src = ./.;
                nativeBuildInputs = deps;
                buildInputs = with pkgs; [ git bash ];
                buildPhase = ''
                    mkdir -p $out/bin
                    bash $src/compile.sh build
                    chmod +x build
                '';
                installPhase = ''
                    mkdir -p $out/bin
                    cp build $out/bin/lux-build-test
                '';
                meta = with pkgs.lib; {
                    description = "Lux build test project";
                    license = licenses.gpl3;
                    maintainers = with maintainers; [ ];
                    platforms = platforms.all;
                };
            };
        });
}
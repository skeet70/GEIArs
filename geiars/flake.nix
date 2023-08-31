{
  description = "Devshell for working with geiars.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
          # need unfree for cudatoolkit (nvidia)
          config.allowUnfree = true;
        };
        rusttoolchain =
          pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      in
      rec {
        # nix develop
        devShell = pkgs.mkShell {
          # TODO: clean this up, shouldn't install all the CUDA stuff if someone is on mac and can't use it
          buildInputs = with pkgs;
            [
              rusttoolchain
              pkg-config
              cudatoolkit
              # built without this, but fails at runtime
              linuxPackages.nvidia_x11
              git-lfs
              # cudaPackages.cudnn
              # stdenv.cc
              # libGLU
              # libGL
              # xorg.libXi
              # xorg.libXmu
              # freeglut
              # xorg.libXext
              # xorg.libX11
              # xorg.libXv
              # xorg.libXrandr
              # zlib
              # # ncurses5 # probably not needed
              # binutils
              # # ffmpeg # probably not needed
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin
              [ pkgs.darwin.apple_sdk.frameworks.Security ];

          shellHook = ''
            export CUDA_PATH=${pkgs.cudatoolkit}
            export EXTRA_CCFLAGS="-I/usr/include"
            export LD_LIBRARY_PATH="${pkgs.linuxPackages.nvidia_x11}/lib"
            export EXTRA_LDFLAGS="-l/lib -l${pkgs.linuxPackages.nvidia_x11}/lib"
          '';
          # shellHook = ''
          #   export CUDA_PATH=${pkgs.cudatoolkit}
          #   export EXTRA_CCFLAGS="-I/usr/include"
          #   export LD_LIBRARY_PATH="${pkgs.linuxPackages.nvidia_x11}/lib"
          #   export EXTRA_LDFLAGS="-l/lib -l${pkgs.linuxPackages.nvidia_x11}/lib"
          # '';
        };

      });
}

{
  inputs.pyproject.url = "github:adisbladis/pyproject.nix";
  inputs.pyproject.inputs.nixpkgs.follows = "nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, pyproject, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (nixpkgs) lib;

        # Loads pyproject.toml into a high-level project representation
        project = pyproject.lib.project.loadPyproject {
          # Read & unmarshal pyproject.toml
          pyproject = lib.importTOML ./pyproject.toml;
        };
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.cudaSupport = pkgs.stdenvNoCC.isLinux;
        };
        python = pkgs.python310;

      in
      {

        # Create a development shell containing dependencies from `pyproject.toml`
        devShell =
          let
            # Returns a function that can be passed to `python.withPackages`
            arg = pyproject.lib.renderers.withPackages { inherit python project; };

            # Returns a wrapped environment (virtualenv like) with all our packages
            pythonEnv = python.withPackages arg;

          in
          pkgs.mkShell {
            packages = [
              pythonEnv
              # will likely need to move torch from pyproject to here to get cuda support
              # pkgs.python310Packages.torch
              # run `git lfs install --local` to set up
              pkgs.git-lfs
            ];
          };

        # Build our package using `buildPythonPackage
        packages =
          let
            # Returns an attribute set that can be passed to `buildPythonPackage`.
            attrs = pyproject.lib.renderers.buildPythonPackage { inherit python project; };
          in
          python.pkgs.buildPythonPackage attrs;
      });
}

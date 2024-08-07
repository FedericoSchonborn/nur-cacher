{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    { systems, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;

      perSystem =
        { pkgs, ... }:
        {
          # Adapted from https://kokada.capivaras.dev/blog/generating-yaml-files-with-nix/
          # TODO: DRY this crap
          packages.workflows =
            pkgs.runCommand "workflows"
              {
                buildInputs = with pkgs; [
                  action-validator
                  yj
                ];
                mainJSON = builtins.toJSON (import ./workflows/main.nix);
                buildJSON = builtins.toJSON (import ./workflows/build.nix);
                passAsFile = [
                  "mainJSON"
                  "buildJSON"
                ];
              }
              ''
                mkdir -p $out
                yj -jy < "$mainJSONPath" > $out/main.yaml
                yj -jy < "$buildJSONPath" > $out/build.yaml
                action-validator -v $out/main.yaml
                action-validator -v $out/build.yaml
              '';

          devShells.default = pkgs.mkShell { packages = with pkgs; [ actionlint ]; };

          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}

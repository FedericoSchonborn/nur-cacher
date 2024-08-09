{
  inputs = {
    nixpkgs.follows = "nixpkgs-unstable";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixos-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixos-stable-small.url = "github:NixOS/nixpkgs/nixos-24.05-small";
    nixpkgs-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";

    systems.url = "github:nix-systems/default";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    { systems, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        systems = import systems;

        flake.lib = import ./lib;

        perSystem =
          { pkgs, config, ... }:
          {
            # Adapted from https://kokada.capivaras.dev/blog/generating-yaml-files-with-nix/
            # TODO: DRY this crap
            packages.workflows =
              pkgs.runCommand "workflows"
                {
                  buildInputs = with pkgs; [
                    actionlint
                    yj
                  ];
                  mainJSON = builtins.toJSON (import ./workflows/main.nix self.lib);
                  buildJSON = builtins.toJSON (import ./workflows/build.nix self.lib);
                  passAsFile = [
                    "mainJSON"
                    "buildJSON"
                  ];
                }
                ''
                  mkdir -p $out
                  yj -jy < "$mainJSONPath" > $out/main.yaml
                  yj -jy < "$buildJSONPath" > $out/build.yaml
                  actionlint $out/main.yaml $out/build.yaml
                '';

            devShells.default = pkgs.mkShell { inputsFrom = builtins.attrValues config.packages; };

            formatter = pkgs.nixfmt-rfc-style;
          };
      }
    );
}

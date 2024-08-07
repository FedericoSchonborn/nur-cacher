let
  lib = import ../lib;
in

{
  name = "Build";

  on.workflow_call.inputs = {
    runs-on = {
      type = "string";
      required = true;
    };
    system = {
      type = "string";
      required = true;
    };
    channel = {
      type = "string";
      required = true;
    };
  };

  env.CACHIX_NAME = "federicoschonborn";

  jobs.build = {
    name = "Build";
    runs-on = lib.ref "inputs.runs-on";

    steps = [
      {
        name = "Checkout";
        uses = "actions/checkout@v4";
        "with".repository = "https://codeberg.org/FedericoSchonborn/nur-packages";
      }

      {
        name = "Setup QEMU";
        "if" = "inputs.runs-on == 'ubuntu-latest' && !contains(fromJSON('[\"x86_64-linux\"]'), inputs.system)";
        uses = "docker/setup-qemu-action@v3";
      }

      {
        name = "Setup Nix";
        uses = "DeterminateSystems/nix-installer-action@v9";
        "with" = {
          extra-conf = ''
            nix-path = nixpkgs=channel:${lib.ref "inputs.channel"}
            system = ${lib.ref "inputs.system"}
          '';
        };
      }

      {
        name = "Setup Magic Nix Cache";
        uses = "DeterminateSystems/magic-nix-cache-action@v2";
      }

      {
        name = "Setup Cachix";
        "if" = "contains(fromJSON('[\"x86_64-linux\", \"aarch64-linux\"]'), inputs.system)";
        uses = "cachix/cachix-action@v13";
        "with" = {
          authToken = lib.ref "secrets.CACHIX_AUTH_TOKEN";
          name = lib.ref "env.CACHIX_NAME";
        };
      }

      {
        name = "Show Nixpkgs version";
        run = ''
          nix eval --impure --raw --expr "(import <nixpkgs> {}).lib.version"
        '';
      }

      {
        name = "Check evaluation";
        run = ''
          nix eval --impure --json --expr "builtins.mapAttrs (name: value: value.meta or {}) (import ./. {})"
        '';
      }

      {
        name = "Build Nix packages";
        run = ''
          nix run nixpkgs#nix-build-uncached -- ci.nix -A cacheOutputs -build-flags "-L"
        '';
      }
    ];
  };
}

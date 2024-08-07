let
  lib = import ../lib;
in

{
  name = "Build";

  on.workflow_call.inputs = {
    runner = {
      type = "string";
      required = true;
    };
    buildSystem = {
      type = "string";
      required = true;
    };
    targetSystem = {
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
    runs-on = lib.ref "inputs.runner";

    steps = [
      {
        name = "Checkout";
        run = ''
          git clone --depth 1 https://codeberg.org/FedericoSchonborn/nur-packages $GITHUB_WORKSPACE
        '';
      }

      {
        name = "Setup QEMU";
        "if" = "inputs.runner == '${lib.runners.ubuntu}' && inputs.targetSystem != inputs.buildSystem";
        uses = "docker/setup-qemu-action@v3";
      }

      {
        name = "Setup Nix";
        uses = "DeterminateSystems/nix-installer-action@v13";
        "with" = {
          source-url = "https://install.lix.systems/lix/lix-installer-${lib.ref "inputs.buildSystem"}";
          nix-package-url = "https://releases.lix.systems/lix/lix-${lib.lixVersion}/lix-${lib.lixVersion}-${lib.ref "inputs.buildSystem"}.tar.xz";
        };
      }

      {
        name = "Setup Magic Nix Cache";
        uses = "DeterminateSystems/magic-nix-cache-action@v7";
      }

      {
        name = "Setup Cachix";
        "if" = ''contains(fromJSON('["x86_64-linux", "aarch64-linux", "i686-linux", "x86_64-darwin", "aarch64-darwin"]'), inputs.buildSystem)'';
        uses = "cachix/cachix-action@v15";
        "with" = {
          authToken = lib.ref "secrets.CACHIX_AUTH_TOKEN";
          name = lib.ref "env.CACHIX_NAME";
        };
      }

      {
        name = "Dry Build Nix packages";
        run = ''
          nix build --dry-run --print-build-logs --keep-going --no-link --file ./ci.nix cacheOutputs --system "${lib.ref "inputs.targetSystem"}" --override-flake nixpkgs github:NixOS/nixpkgs/${lib.ref "inputs.channel"}
        '';
      }

      {
        name = "Build Nix packages";
        run = ''
          nix build --print-build-logs --keep-going --no-link --file ./ci.nix cacheOutputs --system "${lib.ref "inputs.targetSystem"}" --override-flake nixpkgs github:NixOS/nixpkgs/${lib.ref "inputs.channel"}
        '';
      }
    ];
  };
}

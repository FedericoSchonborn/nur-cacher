lib:

let
  inherit (lib)
    envRefs
    inputRefs
    inputs
    lixVersion
    runners
    secretRefs
    ;
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
    runs-on = inputRefs.runner;

    steps = [
      {
        name = "Checkout";
        run = ''
          git clone --verbose --depth 1 https://codeberg.org/FedericoSchonborn/nur-packages "$GITHUB_WORKSPACE"
        '';
      }

      {
        name = "Setup QEMU";
        "if" = "${inputs.runner} == '${runners.ubuntu}' && ${inputs.targetSystem} != ${inputs.buildSystem}";
        uses = "docker/setup-qemu-action@v3";
      }

      {
        name = "Setup Nix";
        uses = "DeterminateSystems/nix-installer-action@v13";
        "with" = {
          source-url = "https://install.lix.systems/lix/lix-installer-${inputRefs.buildSystem}";
          nix-package-url = "https://releases.lix.systems/lix/lix-${lixVersion}/lix-${lixVersion}-${inputRefs.buildSystem}.tar.xz";
        };
      }

      {
        name = "Setup Magic Nix Cache";
        uses = "DeterminateSystems/magic-nix-cache-action@v7";
      }

      {
        name = "Setup Cachix";
        "if" =
          let
            systems = [
              "x86_64-linux"
              "aarch64-linux"
              "i686-linux"
              "x86_64-darwin"
              "aarch64-darwin"
            ];
          in
          ''contains(fromJSON('${builtins.toJSON systems}'), ${inputs.buildSystem})'';
        uses = "cachix/cachix-action@v15";
        "with" = {
          authToken = secretRefs.CACHIX_AUTH_TOKEN;
          name = envRefs.CACHIX_NAME;
        };
      }

      {
        name = "Dry Build Nix packages";
        run = ''
          nix build --dry-run --print-build-logs --keep-going --no-link --file ./ci.nix cacheOutputs --system "${inputRefs.targetSystem}" --inputs-from . --override-input nixpkgs ${inputRefs.channel}
        '';
      }

      {
        name = "Build Nix packages";
        run = ''
          nix build --print-build-logs --keep-going --no-link --file ./ci.nix cacheOutputs --system "${inputRefs.targetSystem}" --inputs-from . --override-input nixpkgs ${inputRefs.channel}
        '';
      }
    ];
  };
}

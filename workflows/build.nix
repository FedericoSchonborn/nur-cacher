lib:

let
  inherit (lib)
    envRef
    inputRef
    input
    inputTypes
    lixVersion
    runners
    secretRef
    ;
in

{
  name = "Build";

  on.workflow_call.inputs = {
    runner = with inputTypes; required string;
    buildSystem = with inputTypes; required string;
    targetSystem = with inputTypes; required string;
    channel = with inputTypes; required string;
    flakeInput = with inputTypes; required string;
  };

  env.CACHIX_NAME = "federicoschonborn";

  jobs.build = {
    name = "Build";
    runs-on = inputRef "runner";

    steps = [
      {
        name = "Checkout";
        run = ''
          git clone --verbose --depth 1 https://codeberg.org/FedericoSchonborn/nur-packages "$GITHUB_WORKSPACE"
        '';
      }

      {
        name = "Setup QEMU";
        "if" = "${input "runner"} == '${runners.ubuntu}' && ${input "targetSystem"} != ${input "buildSystem"}";
        uses = "docker/setup-qemu-action@v3";
      }

      {
        name = "Setup Nix";
        uses = "DeterminateSystems/nix-installer-action@v13";
        "with" = {
          source-url = "https://install.lix.systems/lix/lix-installer-${inputRef "buildSystem"}";
          nix-package-url = "https://releases.lix.systems/lix/lix-${lixVersion}/lix-${lixVersion}-${inputRef "buildSystem"}.tar.xz";
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
          ''contains(fromJSON('${builtins.toJSON systems}'), ${input "buildSystem"})'';
        uses = "cachix/cachix-action@v15";
        "with" = {
          authToken = secretRef "CACHIX_AUTH_TOKEN";
          name = envRef "CACHIX_NAME";
        };
      }

      {
        name = "Dry Build Nix packages";
        run = ''
          nix build --dry-run --print-build-logs --keep-going --no-link --impure --file ./ci.nix cacheOutputs --system "${inputRef "targetSystem"}" --inputs-from . --override-input nixpkgs ${inputRef "flakeInput"}
        '';
      }

      {
        name = "Build Nix packages";
        run = ''
          nix build --print-build-logs --keep-going --no-link --impure --file ./ci.nix cacheOutputs --system "${inputRef "targetSystem"}" --inputs-from . --override-input nixpkgs ${inputRef "flakeInput"}
        '';
      }
    ];
  };
}

lib:

let
  inherit (lib) channels optionalAttrs runners;
in

{
  name = "Build and Populate Cache";

  on = {
    pull_request = { };
    push.branches = [ "main" ];
    schedule = [ { cron = "55 3 * * *"; } ];
    workflow_dispatch = { };
  };

  env.NUR_REPO = "federicoschonborn";

  jobs =
    let
      jobName = { channel, system }: "build-${builtins.replaceStrings [ "." ] [ "_" ] channel}-${system}";
    in
    builtins.listToAttrs (
      builtins.map
        (
          {
            runner,
            system ? targetSystem,
            buildSystem ? system,
            targetSystem ? system,
            channel,
            needs ? null,
          }:
          {
            name = jobName {
              inherit channel;
              system = targetSystem;
            };
            value = {
              name =
                let
                  systemParts = builtins.match "(.*)-(.*)" targetSystem;
                  systemArch = builtins.elemAt systemParts 0;
                  systemKernel = builtins.elemAt systemParts 1;

                  channelParts = builtins.match "([^-]*)-([^-]*)-?([^-]*)" channel;
                  channelName = builtins.elemAt channelParts 0;
                  channelVersion = builtins.elemAt channelParts 1;

                  prettyNames = {
                    linux = "Linux";
                    darwin = "Darwin";
                    nixpkgs = "Nixpkgs";
                    nixos = "NixOS";
                    stable = "Stable";
                    unstable = "Unstable";
                  };

                  prettySystemKernel = prettyNames.${systemKernel} or systemKernel;
                  prettySystem = "${prettySystemKernel}/${systemArch}";

                  prettyChannelName = prettyNames.${channelName} or channelName;
                  prettyChannelVersion = prettyNames.${channelVersion} or channelVersion;
                  prettyChannel = "${prettyChannelName} ${prettyChannelVersion}";
                in
                "${prettyChannel} (${prettySystem})";
              uses = "./.github/workflows/build.yaml";
              "with" = {
                inherit
                  runner
                  buildSystem
                  targetSystem
                  channel
                  ;
              };
              secrets = "inherit";
            } // optionalAttrs (builtins.isList needs) { needs = builtins.map jobName needs; };
          }
        )
        [
          {
            runner = runners.ubuntu;
            system = "x86_64-linux";
            channel = channels.nixpkgs.unstable;
          }

          {
            runner = runners.ubuntu;
            buildSystem = "x86_64-linux";
            targetSystem = "aarch64-linux";
            channel = channels.nixpkgs.unstable;
            needs = [
              {
                channel = channels.nixpkgs.unstable;
                system = "x86_64-linux";
              }
            ];
          }

          {
            runner = runners.macos-x86_64;
            system = "x86_64-darwin";
            channel = channels.nixpkgs.unstable;
          }

          {
            runner = runners.macos-aarch64;
            system = "aarch64-darwin";
            channel = channels.nixpkgs.unstable;
            needs = [
              {
                channel = channels.nixpkgs.unstable;
                system = "x86_64-darwin";
              }
            ];
          }

          {
            runner = runners.ubuntu;
            system = "x86_64-linux";
            channel = channels.nixos.unstable;
            needs = [
              {
                channel = channels.nixpkgs.unstable;
                system = "x86_64-linux";
              }
            ];
          }

          {
            runner = runners.ubuntu;
            buildSystem = "x86_64-linux";
            targetSystem = "aarch64-linux";
            channel = channels.nixos.unstable;
            needs = [
              {
                channel = channels.nixpkgs.unstable;
                system = "aarch64-linux";
              }
              {
                channel = channels.nixos.unstable;
                system = "x86_64-linux";
              }
            ];
          }

          {
            runner = runners.ubuntu;
            system = "x86_64-linux";
            channel = channels.nixos.stable;
            needs = [
              {
                channel = channels.nixos.unstable;
                system = "x86_64-linux";
              }
            ];
          }

          {
            runner = runners.ubuntu;
            buildSystem = "x86_64-linux";
            targetSystem = "aarch64-linux";
            channel = channels.nixos.stable;
            needs = [
              {
                channel = channels.nixos.unstable;
                system = "aarch64-linux";
              }
              {
                channel = channels.nixos.stable;
                system = "x86_64-linux";
              }
            ];
          }

          {
            runner = runners.macos-x86_64;
            system = "x86_64-darwin";
            channel = channels.darwin.stable;
            needs = [
              {
                channel = channels.nixpkgs.unstable;
                system = "x86_64-darwin";
              }
            ];
          }

          {
            runner = runners.macos-aarch64;
            system = "aarch64-darwin";
            channel = channels.darwin.stable;
            needs = [
              {
                channel = channels.nixpkgs.unstable;
                system = "aarch64-darwin";
              }
              {
                channel = channels.darwin.stable;
                system = "x86_64-darwin";
              }
            ];
          }
        ]
    );
}

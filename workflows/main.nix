let
  lib = import ../lib;
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
            } // (if builtins.isList needs then { needs = builtins.map jobName needs; } else { });
          }
        )
        [
          {
            runner = lib.runners.ubuntu;
            system = "x86_64-linux";
            channel = lib.channels.nixpkgs.unstable;
          }

          {
            runner = lib.runners.ubuntu;
            buildSystem = "x86_64-linux";
            targetSystem = "aarch64-linux";
            channel = lib.channels.nixpkgs.unstable;
            needs = [
              {
                channel = lib.channels.nixpkgs.unstable;
                system = "x86_64-linux";
              }
            ];
          }

          {
            runner = lib.runners.macos.x86_64;
            system = "x86_64-darwin";
            channel = lib.channels.nixpkgs.unstable;
          }

          {
            runner = lib.runners.macos.aarch64;
            system = "aarch64-darwin";
            channel = lib.channels.nixpkgs.unstable;
            needs = [
              {
                channel = lib.channels.nixpkgs.unstable;
                system = "x86_64-darwin";
              }
            ];
          }

          {
            runner = lib.runners.ubuntu;
            system = "x86_64-linux";
            channel = lib.channels.nixos.unstable;
            needs = [
              {
                channel = lib.channels.nixpkgs.unstable;
                system = "x86_64-linux";
              }
            ];
          }

          {
            runner = lib.runners.ubuntu;
            buildSystem = "x86_64-linux";
            targetSystem = "aarch64-linux";
            channel = lib.channels.nixos.unstable;
            needs = [
              {
                channel = lib.channels.nixpkgs.unstable;
                system = "aarch64-linux";
              }
              {
                channel = lib.channels.nixos.unstable;
                system = "x86_64-linux";
              }
            ];
          }

          {
            runner = lib.runners.ubuntu;
            system = "x86_64-linux";
            channel = lib.channels.nixos.stable;
            needs = [
              {
                channel = lib.channels.nixos.unstable;
                system = "x86_64-linux";
              }
            ];
          }

          {
            runner = lib.runners.ubuntu;
            buildSystem = "x86_64-linux";
            targetSystem = "aarch64-linux";
            channel = lib.channels.nixos.stable;
            needs = [
              {
                channel = lib.channels.nixos.unstable;
                system = "aarch64-linux";
              }
              {
                channel = lib.channels.nixos.stable;
                system = "x86_64-linux";
              }
            ];
          }

          {
            runner = lib.runners.macos.x86_64;
            system = "x86_64-darwin";
            channel = lib.channels.darwin.stable;
            needs = [
              {
                channel = lib.channels.nixpkgs.unstable;
                system = "x86_64-darwin";
              }
            ];
          }

          {
            runner = lib.runners.macos.aarch64;
            system = "aarch64-darwin";
            channel = lib.channels.darwin.stable;
            needs = [
              {
                channel = lib.channels.nixpkgs.unstable;
                system = "aarch64-darwin";
              }
              {
                channel = lib.channels.darwin.stable;
                system = "x86_64-darwin";
              }
            ];
          }
        ]
    );
}

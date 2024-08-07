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

  jobs = {
    build-nixpkgs-unstable-x86_64-linux = {
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = lib.runners.ubuntu.x86_64;
        system = "x86_64-linux";
        channel = lib.channels.nixpkgs.unstable;
      };
    };

    build-nixpkgs-unstable-aarch64-linux = {
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = lib.runners.ubuntu.x86_64;
        system = "aarch64-linux";
        channel = lib.channels.nixpkgs.unstable;
      };
    };

    build-nixpkgs-unstable-x86_64-darwin = {
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = lib.runners.macos.x86_64;
        system = "x86_64-darwin";
        channel = lib.channels.nixpkgs.unstable;
      };
    };

    build-nixpkgs-unstable-aarch64-darwin = {
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = lib.runners.macos.aarch64;
        system = "aarch64-darwin";
        channel = lib.channels.nixpkgs.unstable;
      };
    };

    build-nixos-unstable-x86_64-linux = {
      needs = [ "build-nixpkgs-unstable-x86_64-linux" ];
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = lib.runners.ubuntu.x86_64;
        system = "x86_64-linux";
        channel = lib.channels.nixos.unstable;
      };
    };

    build-nixos-unstable-aarch64-linux = {
      needs = [ "build-nixpkgs-unstable-aarch64-linux" ];
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = lib.runners.ubuntu.x86_64;
        system = "aarch64-linux";
        channel = lib.channels.nixos.unstable;
      };
    };

    build-nixos-stable-x86_64-linux = {
      needs = [ "build-nixos-unstable-x86_64-linux" ];
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = lib.runners.ubuntu.x86_64;
        system = "x86_64-linux";
        channel = lib.channels.nixos.stable;
      };
    };

    build-nixos-stable-aarch64-linux = {
      needs = [ "build-nixos-unstable-aarch64-linux" ];
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = lib.runners.ubuntu.x86_64;
        system = "aarch64-linux";
        channel = lib.channels.nixos.stable;
      };
    };

    build-nixpkgs-stable-x86_64-darwin = {
      needs = [ "build-nixpkgs-unstable-x86_64-darwin" ];
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = lib.runners.macos.x86_64;
        system = "x86_64-darwin";
        channel = lib.channels.darwin.stable;
      };
    };

    build-nixpkgs-stable-aarch64-darwin = {
      needs = [ "build-nixpkgs-unstable-aarch64-darwin" ];
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = lib.runners.macos.aarch64;
        system = "aarch64-darwin";
        channel = lib.channels.darwin.stable;
      };
    };

    deploy = {
      name = "Deploy";
      runs-on = lib.runners.ubuntu.x86_64;
      needs = [
        "build-nixos-stable-x86_64-linux"
        "build-nixos-stable-aarch64-linux"
        "build-nixpkgs-stable-x86_64-darwin"
        "build-nixpkgs-stable-aarch64-darwin"
      ];
      steps = [
        {
          name = "Trigger NUR update";
          run = ''
            curl -XPOST https://nur-update.herokuapp.com/update?repo=${lib.ref "env.NUR_REPO"}
          '';
        }
      ];
    };
  };
}

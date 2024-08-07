let
  lib = import ../lib;

  ubuntuRunner = "ubuntu-22.04";
  stableVersion = "24.05";
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
        runs-on = ubuntuRunner;
        system = "x86_64-linux";
        channel = "nixpkgs-unstable";
      };
    };

    build-nixpkgs-unstable-aarch64-linux = {
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = ubuntuRunner;
        system = "aarch64-linux";
        channel = "nixpkgs-unstable";
      };
    };

    build-nixos-unstable-x86_64-linux = {
      needs = [ "build-nixpkgs-unstable-x86_64-linux" ];
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = ubuntuRunner;
        system = "x86_64-linux";
        channel = "nixos-unstable";
      };
    };

    build-nixos-unstable-aarch64-linux = {
      needs = [ "build-nixpkgs-unstable-aarch64-linux" ];
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = ubuntuRunner;
        system = "aarch64-linux";
        channel = "nixos-unstable";
      };
    };

    build-nixos-stable-x86_64-linux = {
      needs = [ "build-nixos-unstable-x86_64-linux" ];
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = ubuntuRunner;
        system = "x86_64-linux";
        channel = "nixos-${stableVersion}";
      };
    };

    build-nixos-stable-aarch64-linux = {
      needs = [ "build-nixos-unstable-aarch64-linux" ];
      secrets = "inherit";
      uses = "./.github/workflows/build.yaml";
      "with" = {
        runs-on = ubuntuRunner;
        system = "aarch64-linux";
        channel = "nixos-${stableVersion}";
      };
    };

    deploy = {
      name = "Deploy";
      runs-on = ubuntuRunner;
      needs = [
        "build-nixos-stable-x86_64-linux"
        "build-nixos-stable-aarch64-linux"
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

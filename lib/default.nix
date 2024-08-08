let
  genAttrs =
    xs: f:
    builtins.listToAttrs (
      builtins.map (x: {
        name = x;
        value = f x;
      }) xs
    );

  mkRef = x: "\${{ ${x} }}";

  mkInput = x: "inputs.${x}";
  mkInputRef = x: mkRef (mkInput x);

  inputNames = [
    "runner"
    "buildSystem"
    "targetSystem"
    "channel"
  ];

  inputs = genAttrs inputNames mkInput;
  inputRefs = genAttrs inputNames mkInputRef;

  mkSecret = x: "secrets.${x}";
  mkSecretRef = x: mkRef (mkSecret x);

  secretNames = [ "CACHIX_AUTH_TOKEN" ];

  secrets = genAttrs secretNames mkSecret;
  secretRefs = genAttrs secretNames mkSecretRef;

  mkEnv = x: "env.${x}";
  mkEnvRef = x: mkRef (mkEnv x);

  envNames = [ "CACHIX_NAME" ];

  envs = genAttrs envNames mkEnv;
  envRefs = genAttrs envNames mkEnvRef;

  runners = {
    ubuntu = "ubuntu-22.04";
    macos = {
      x86_64 = "macos-13";
      aarch64 = "macos-14";
    };
  };

  lixVersion = "2.90.0";

  nixpkgsVersion = {
    oldStable = "23.11";
    stable = "24.05";
    unstable = "unstable";
  };

  channels = {
    nixpkgs = builtins.mapAttrs (_: version: "nixpkgs-${version}") {
      inherit (nixpkgsVersion) unstable;
    };

    nixos = builtins.mapAttrs (_: version: "nixos-${version}") {
      inherit (nixpkgsVersion) oldStable stable unstable;
    };

    darwin = builtins.mapAttrs (_: version: "nixpkgs-${version}-darwin") {
      inherit (nixpkgsVersion) oldStable stable;
    };
  };
in
{
  inherit
    mkRef
    mkInput
    mkInputRef
    inputs
    inputRefs
    mkSecret
    mkSecretRef
    secrets
    secretRefs
    mkEnv
    mkEnvRef
    envs
    envRefs
    runners
    lixVersion
    nixpkgsVersion
    channels
    ;
}

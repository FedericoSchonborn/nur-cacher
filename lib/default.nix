let
  genAttrs =
    xs: f:
    builtins.listToAttrs (
      builtins.map (x: {
        name = x;
        value = f x;
      }) xs
    );

  optionalAttrs = p: attrs: if p then attrs else { };

  mkRef = x: "\${{ ${x} }}";

  input = x: "inputs.${x}";
  inputRef = x: mkRef (input x);

  secret = x: "secrets.${x}";
  secretRef = x: mkRef (secret x);

  env = x: "env.${x}";
  envRef = x: mkRef (env x);

  inputTypes =
    let
      required = attrs: attrs // { required = true; };
      optional = attrs: attrs // { required = false; };
    in
    {
      inherit required optional;
      string.type = "string";
    };

  runners = {
    ubuntu = "ubuntu-22.04";
    macos-x86_64 = "macos-13";
    macos-aarch64 = "macos-14";
  };

  lixVersion = "2.90.0";

  nixpkgsVersion = {
    stable = "24.05";
    unstable = "unstable";
  };

  channels = {
    nixpkgs = builtins.mapAttrs (_: version: "nixpkgs-${version}") {
      inherit (nixpkgsVersion) unstable;
    };

    nixos = builtins.mapAttrs (_: version: "nixos-${version}") {
      inherit (nixpkgsVersion) stable unstable;
    };

    nixos-small = builtins.mapAttrs (_: version: "nixos-${version}-small") {
      inherit (nixpkgsVersion) stable unstable;
    };

    darwin = builtins.mapAttrs (_: version: "nixpkgs-${version}-darwin") {
      inherit (nixpkgsVersion) stable;
    };
  };
in
{
  inherit
    genAttrs
    optionalAttrs
    mkRef
    input
    inputRef
    inputTypes
    secret
    secretRef
    env
    envRef
    runners
    lixVersion
    nixpkgsVersion
    channels
    ;
}

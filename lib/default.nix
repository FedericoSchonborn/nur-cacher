let
  ref = x: "\${{ ${x} }}";

  runners = {
    ubuntu = "ubuntu-22.04";
    macos = {
      x86_64 = "macos-13";
      aarch64 = "macos-14";
    };
  };

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
    ref
    runners
    nixpkgsVersion
    channels
    ;
}

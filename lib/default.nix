let
  ref = x: "\${{ ${x} }}";

  runners = {
    ubuntu.x86_64 = "ubuntu-22.04";
    macos = {
      x86_64 = "macos-13";
      aarch64 = "macos-14";
    };
  };

  stableVersion = "24.05";
  channels = {
    nixpkgs.unstable = "nixpkgs-unstable";
    nixos = {
      stable = "nixos-${stableVersion}";
      unstable = "nixos-unstable";
    };
    darwin.stable = "nixpkgs-${stableVersion}-darwin";
  };
in
{
  inherit
    ref
    runners
    stableVersion
    channels
    ;
}

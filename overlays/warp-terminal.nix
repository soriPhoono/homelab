{inputs, ...}: _final: prev: let
  pkgs = import inputs.nixpkgs-master {
    inherit (prev.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in {
  inherit (pkgs) warp-terminal;
}

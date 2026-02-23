{inputs, ...}: _final: prev: {
  inherit (inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}) antigravity;
}

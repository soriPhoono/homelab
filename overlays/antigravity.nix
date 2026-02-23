{inputs, ...}: _final: prev: {
  antigravity = inputs.antigravity-nix.packages.${prev.stdenv.hostPlatform.system}.default;
}

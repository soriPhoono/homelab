{inputs, ...}: _final: prev: {
  hermes-desktop = inputs.hermes-agent.packages.${prev.stdenv.hostPlatform.system}.desktop;
  hermes-full = inputs.hermes-agent.packages.${prev.stdenv.hostPlatform.system}.full;
}

{inputs, ...}: _final: prev: {
  hermes = inputs.hermes-agent.packages.${prev.stdenv.hostPlatform.system}.default;
  hermes-desktop = inputs.hermes-agent.packages.${prev.stdenv.hostPlatform.system}.desktop;
}

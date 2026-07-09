{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.apps.development.agents.hermes;

  providerOptions = {
    ollama = {
      options = {
        enable = mkEnableOption "Enable ollama provider for hermes agents";
        useCloudModules = mkEnableOption "Enable ollama cloud provider api key integration for hermes agents";
      };
    };
  };
in {
  # Installs cli tooling with global enable option, extra features get added with other options
  options.apps.development.agents.hermes = homelab.agentics.mkAgent {
    name = "hermes";
    package = pkgs.hermes;
    extraOptions = {
      enableDesktop = mkEnableOption "Enable desktop integration for hermes agents";

      providers = providerOptions;

      profiles = mkOption {
        type = types.attrsOf (types.submodule {
          options = homelab.agentics.mkAgentProfile {
            name = "hermes";
            extraOptions = {
            };
          };
        });
        default = {};
        description = "Profiles for the Hermes agent.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
    }
  ]);
}

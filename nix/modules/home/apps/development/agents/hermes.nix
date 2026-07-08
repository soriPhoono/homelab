{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.development.agents.hermes;
in
  with lib; {
    options.apps.development.agents.hermes = homelab.agentics.mkAgent {
      name = "hermes";
      package = pkgs.hermes;
      extraOptions = {
        enableDesktop = mkEnableOption "Enable desktop integration for hermes agents";

        providers = {
          ollama = {
            enable = mkEnableOption "Enable ollama provider for hermes agents";
            useCloudModules = mkEnableOption "Enable ollama cloud provider api key integration for hermes agents";
          };
        };

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
      (mkIf cfg.enableDesktop {home.packages = optional cfg.enableDesktop pkgs.hermes-desktop;})
    ]);
  }

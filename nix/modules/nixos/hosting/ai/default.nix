{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.ai;
in
  with lib; {
    imports = [
      ./hermes
    ];

    options.hosting.ai.enable = mkEnableOption "Enable the local AI agent stack (Hermes Agent)";

    config = mkIf cfg.enable {
      hosting.hermes-agent.enable = true;
    };
  }

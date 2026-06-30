{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.services.hermes;
in
  with lib; {
    imports = [
    ];

    options.services.hermes = {
      enable = mkEnableOption "Enable hermes agent for this user";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        programs.hermes-agent = {
          enable = true;

          package = pkgs.hermes-full;
          extraPackages = with pkgs; [
            pkgs.agent-browser
          ];
        };
      }
    ]);
  }

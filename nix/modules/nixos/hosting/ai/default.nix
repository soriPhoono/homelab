{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.ai;
in
  with lib; {
    imports = [
      ./n8n.nix
      ./mongodb.nix
    ];

    options.hosting.ai = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable AI hosting services";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting.ai.n8n.enable = true;
      }
    ]);
  }

{
  lib,
  config,
  ...
}: let
  cfg = config.core;
in
  with lib; {
    options.core = {
      enable = mkEnableOption "The root neovim configuration module";
    };

    config = mkIf cfg.enable (mkMerge [
      {
      }
    ]);
  }

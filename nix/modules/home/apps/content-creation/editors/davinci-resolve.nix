{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.content-creation.editors.davinci-resolve;

  davinci-resolve-wrapped = pkgs.symlinkJoin {
    name = "davinci-resolve";
    paths = [pkgs.davinci-resolve];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/davinci-resolve \
        --set DRI_PRIME 1
    '';
  };
in
  with lib; {
    options.apps.content-creation.editors.davinci-resolve = {
      enable = mkEnableOption "DaVinci Resolve";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.packages = [
          davinci-resolve-wrapped
        ];
      }
    ]);
  }

{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.content-creation.editors.davinci-resolve;

  davinci-resolve = pkgs.davinci-resolve.override {
    runCommandLocal = name: attrs: command:
      pkgs.runCommandLocal name (attrs
        // {
          outputHash = "sha256-+3SB32EHpH9/0hM3h8CrO6f7V4ZAmxUFh3P8m6QDeO0=";
        })
      command;
  };

  davinci-resolve-wrapped = pkgs.symlinkJoin {
    name = "davinci-resolve";
    paths = [davinci-resolve];
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

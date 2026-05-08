{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.github-copilot;
in
  with lib; {
    options.userapps.development.agents.github-copilot = {
      enable = mkEnableOption "GitHub Copilot agent tooling";
    };

    config = mkIf cfg.enable {
      home.packages = optionals (pkgs ? gh-copilot) [pkgs.gh-copilot];

      warnings = optional (!(pkgs ? gh-copilot)) ''
        userapps.development.agents.github-copilot is enabled, but `pkgs.gh-copilot` is unavailable in this nixpkgs.
      '';
    };
  }

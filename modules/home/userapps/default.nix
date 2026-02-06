{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps;
in
  with lib; {
    imports = [
      ./browsers/firefox.nix
      ./browsers/librewolf.nix
      ./browsers/chrome.nix
      ./browsers/floorp.nix

      ./development/agents/claude.nix
      ./development/agents/gemini.nix

      ./development/editors/vscode.nix
      ./development/editors/neovim.nix

      ./development/terminal/kitty.nix
      ./development/terminal/ghostty.nix
    ];

    options.userapps = {
      enable = mkEnableOption "Enable core applications and default feature-set";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        nextcloud-client
        bitwarden-desktop
        obsidian
        onlyoffice-desktopeditors

        discord
      ];

      services = {
        psd = {
          enable = true;
          resyncTimer = "10m";
        };
      };
    };
  }

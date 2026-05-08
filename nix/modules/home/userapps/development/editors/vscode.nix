# TODO: finish implementing mcp servers for antigravity to comply with immutable extension dirs
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.vscode;
in
  with lib; {
    options.userapps.development.editors.vscode = {
      enable = mkEnableOption "Enable vscode text editor";

      vendor = mkOption {
        type = with types; enum ["oss-code" "vscode" "cursor"];
        default = "oss-code";
        description = ''
          Which VSCode-family editor vendor to use.
          - "oss-code" -> default (pkgs.vscodium)
          - "vscode" -> pkgs.vscode
          - "cursor" -> pkgs.code-cursor
        '';
      };

      priority = mkOption {
        type = types.int;
        default = 40;
        description = "Priority for being the default editor. Lower is higher priority.";
      };

      extensions = mkOption {
        type = with types; listOf package;
        default = [];
        description = "List of VSCode extensions to install.";
      };

      userSettings = mkOption {
        type = with types; attrs;
        default = {};
        description = "User settings for VSCode.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      (let
        package =
          if cfg.vendor == "vscode"
          then pkgs.vscode
          else if cfg.vendor == "cursor"
          then pkgs.code-cursor
          else if cfg.vendor == "oss-code"
          then pkgs.vscodium
          else null;
      in {
        home.sessionVariables = {
          EDITOR = mkOverride cfg.priority (lib.getExe package);
          VISUAL = mkOverride cfg.priority (lib.getExe package);
        };

        xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
          editor = ["${baseNameOf (lib.getExe package)}.desktop"];
        in
          mkOverride cfg.priority {
            "text/plain" = editor;
            "text/markdown" = editor;
            "application/x-shellscript" = editor;
          });

        programs.vscode = {
          inherit package;

          enable = true;
          mutableExtensionsDir = false;

          profiles.default = {
            inherit (cfg) extensions userSettings;

            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
          };
        };
      })
      (mkIf (cfg.vendor != "oss-code") {
        userapps.development.infrastructure.github = {
          enable = mkDefault true;
          enableDesktop = mkDefault true;
        };
      })
      (mkIf (cfg.vendor == "vscode") {
        userapps.development.agents.github-copilot = {
          enable = mkDefault true;
        };
      })
      (mkIf (cfg.vendor == "cursor") {
        userapps.development.agents.cursor = {
          enable = mkDefault true;
        };
      })
    ]);
  }

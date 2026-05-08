# TODO: finish implementing mcp servers for antigravity to comply with immutable extension dirs
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.vscode;
  cursorAgentsCfg = config.userapps.development.agents.cursor;
  cursorAgentCliEnabled =
    if cfg.cursorAgentCli.enable == null
    then cfg.package.pname == "cursor"
    else cfg.cursorAgentCli.enable;
  cursorCliInstalledByAgents = cursorAgentsCfg.enable && cursorAgentsCfg.secrets != [];
in
  with lib; {
    options.userapps.development.editors.vscode = {
      enable = mkEnableOption "Enable vscode text editor";

      cursorAgentCli = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = ''
            Install the Cursor Agent CLI (`cursor-agent` from pkgs.cursor-cli) alongside the editor.
            When null, it enables automatically when `package.pname` is `"cursor"` (the `code-cursor` package).
            Disabled automatically when `userapps.development.agents.cursor` supplies a secret-wrapped CLI.
          '';
        };
      };

      package = mkOption {
        type = types.package;
        default = pkgs.vscodium;
        description = "The vscode package to use.";
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

    config = mkMerge [
      (mkIf cfg.enable {
        home.sessionVariables = {
          EDITOR = mkOverride cfg.priority (lib.getExe cfg.package);
          VISUAL = mkOverride cfg.priority (lib.getExe cfg.package);
        };

        xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
          editor = ["${baseNameOf (lib.getExe cfg.package)}.desktop"];
        in
          mkOverride cfg.priority {
            "text/plain" = editor;
            "text/markdown" = editor;
            "application/x-shellscript" = editor;
          });

        programs.vscode = {
          inherit (cfg) package;

          enable = true;
          mutableExtensionsDir = false;

          profiles.default = {
            inherit (cfg) extensions userSettings;

            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
          };
        };
      })
      (mkIf (cfg.enable && cursorAgentCliEnabled && !cursorCliInstalledByAgents) {
        home.packages = [pkgs.cursor-cli];
      })
    ];
  }

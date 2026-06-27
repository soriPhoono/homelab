/*
Zed editor module
- Requires dynamically enabling github desktop (DONE)
- Requires setting mime associations for text (DONE)
- Configure settings for editor (e.g. font, theme) (DONE)
- Install editor extensions (DONE)
- Configure stylix for editor (optional) (DONE)
*/
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.zed;

  codeMimeTypes = [
    "inode/x-empty"
    "text/plain"
    "text/markdown"
    "text/x-markdown"
    "text/javascript"
    "text/css"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/x-cmake"
    "text/x-diff"
    "text/x-go"
    "text/x-java"
    "text/x-kotlin"
    "text/x-lua"
    "text/x-makefile"
    "text/x-nix"
    "text/x-python"
    "text/x-ruby"
    "text/x-rust"
    "text/x-script.python"
    "text/x-shellscript"
    "text/x-sql"
    "text/x-toml"
    "text/x-typescript"
    "text/x-typescript-jsx"
    "text/x-yaml"
    "application/json"
    "application/ld+json"
    "application/javascript"
    "application/toml"
    "application/xml"
    "application/x-shellscript"
    "application/x-yaml"
  ];
in
  with lib; {
    options.userapps.development.editors.zed = homelab.agentics.mkEditor {
      name = "zed";
      package = pkgs.zed-editor;
      extraOptions = {
        extensions = mkOption {
          type = with types; listOf str;
          default = [];
          description = "List of Zed extensions to install.";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        # Default editor session variables
        home.sessionVariables = mkIf cfg.defaultEditor {
          EDITOR = "${lib.getExe cfg.package}";
          VISUAL = "${lib.getExe cfg.package}";
        };

        # Extra packages (LSP servers, formatters, linters)
        home.packages = cfg.extraPackages;

        # MIME type associations
        xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (
          let
            editor = ["${baseNameOf (lib.getExe cfg.package)}.desktop"];
          in
            mkOverride cfg.priority (
              builtins.listToAttrs (map (mime: lib.nameValuePair mime editor) codeMimeTypes)
            )
        );

        # Zed editor upstream module
        programs.zed-editor = {
          enable = true;
          inherit (cfg) package;

          inherit (cfg) extensions userSettings;

          mutableUserDebug = false;
          mutableUserKeymaps = false;
          mutableUserSettings = false;
          mutableUserTasks = false;
        };
      }
    ]);
  }

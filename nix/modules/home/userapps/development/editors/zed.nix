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
    options.userapps.development.editors.zed = {
      enable = mkEnableOption "Enable zed text editor";

      priority = mkOption {
        type = types.int;
        description = "The priority of the zed editor";
        default = 20; # Clean this up by referencing basic common priorities from a global import
      };

      secrets = mkOption {
        type = with types; listOf str;
        description = ''
          List of secrets to inject into the Zed editor environment. These should be
          paths to files containing the secrets, and the file names (without extensions)
          will be used as environment variable names.
        '';
        default = [];
      };

      userSettings = mkOption {
        type = with types; attrs;
        default = {};
        description = "User settings for Zed.";
      };

      extensions = mkOption {
        type = with types; listOf str;
        default = [];
        description = "List of Zed extensions to install.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (
          let
            editor = ["${baseNameOf (lib.getExe config.programs.zed-editor.package)}.desktop"];
          in
            mkOverride cfg.priority (
              builtins.listToAttrs (map (mime: lib.nameValuePair mime editor) codeMimeTypes)
            )
        );

        programs.zed-editor = {
          inherit (cfg) extensions userSettings;

          enable = true;

          mutableUserDebug = false;
          mutableUserKeymaps = false;
          mutableUserSettings = false;
          mutableUserTasks = false;
        };
      }
    ]);
  }

{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.editors.zed;
in
  with lib; {
    options.userapps.development.editors.zed = let
      jsonFormat = pkgs.formats.json {};
    in {
      enable = mkEnableOption "Enable zed editors";

      package = mkOption {
        type = types.package;
        description = "The package to use for zed, e.g.: pkgs.zed-editor or pkgs.zed-editor-fhs";
        default = pkgs.zed-editor;
      };

      priority = mkOption {
        type = types.int;
        description = "The priority of the zed editor";
        default = 30;
      };

      secrets = mkOption {
        type = with types; listOf str;
        description = "List of secrets to inject into zed.";
        default = [];
      };

      userKeymaps = mkOption {
        inherit (jsonFormat) type;
        description = "User keymaps for zed editor";
        default = [];
      };

      userTasks = mkOption {
        inherit (jsonFormat) type;
        description = "User tasks for zed editor";
        default = [];
      };

      userDebug = mkOption {
        inherit (jsonFormat) type;
        description = "User debug settings for zed editor";
        default = {};
      };

      userSettings = mkOption {
        inherit (jsonFormat) type;
        description = "User settings for zed editor";
        default = {};
      };

      extensions = mkOption {
        type = with types; listOf str;
        description = "Names of extensions to auto install from [the master list](https://github.com/zed-industries/extensions/tree/main/extensions)";
        default = [];
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.sessionVariables = {
          EDITOR = mkOverride cfg.priority (lib.getExe cfg.package);
          VISUAL = mkOverride cfg.priority (lib.getExe cfg.package);
        };

        xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
          editor = ["${lib.getExe cfg.package}.desktop"];
        in
          mkOverride cfg.priority {
            "text/plain" = editor;
            "text/markdown" = editor;
            "application/x-shellscript" = editor;
          });

        programs.zed-editor = {
          inherit
            (cfg)
            package
            userKeymaps
            userTasks
            userDebug
            userSettings
            extensions
            ;

          enable = true;

          mutableUserDebug = false;
          mutableUserKeymaps = false;
          mutableUserSettings = false;
          mutableUserTasks = false;
        };
      }
      (mkIf (options ? sops && cfg.secrets != []) {
        sops.secrets = genAttrs cfg.secrets (_: {});

        programs.zed-editor.package = mkForce (pkgs.symlinkJoin {
          name = "zed-editor-wrapped";
          paths = [cfg.package];
          buildInputs = [pkgs.makeWrapper];
          postBuild = ''
            for bin in $out/bin/*; do
              if [ -f "$bin" ] && [ -x "$bin" ]; then
                wrapProgram "$bin" \
                  ${
              concatStringsSep
              " \\\n"
              (map
                (secret: "--run '[ -f ${config.sops.secrets.${secret}.path} ] && export ${baseNameOf secret}=\"$(cat ${config.sops.secrets.${secret}.path})\"'")
                cfg.secrets)
            }
              fi
            done
          '';
        });
      })
    ]);
  }

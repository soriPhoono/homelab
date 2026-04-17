# TODO: fix secrets handling, can't bake secrets into package when it can simply be placed in the configuration file
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
    options.userapps.development.editors.zed = {
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
    };

    config = mkIf cfg.enable (mkMerge [
      {
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

        programs.zed-editor = {
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
          pname = cfg.package.pname or "zed";
          version = cfg.package.version or "latest";
          name = "${cfg.package.name or "zed-editor"}-with-secrets";

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

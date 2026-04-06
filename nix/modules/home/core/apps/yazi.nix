{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.apps.yazi;
in
  with lib; {
    options.core.apps.yazi = {
      enable = mkEnableOption "Enable yazi terminal file browser";

      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "The extra settings to inject into yazi";
      };

      plugins = mkOption {
        type = with types; attrsOf (oneOf [path package]);
        default = {};
        description = "The extra plugins to inject into yazi";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        programs.yazi = {
          enable = true;
          inherit (cfg) plugins;
          inherit (cfg) settings;
        };
      }

      (mkIf (pkgs ? yaziPlugins && pkgs.yaziPlugins ? gvfs) {
        programs.yazi = {
          extraPackages = with pkgs; [glib];

          plugins = {
            inherit (pkgs.yaziPlugins) gvfs;
          };

          initLua = ''
            require("gvfs"):setup({
              password_vault = "keyring",
              save_password_autoconfirm = true
            })
          '';

          settings.plugin = {
            prepend_preloaders = [
              # Do not preload files in mounted locations
              {
                url = "/run/user/1000/gvfs/**/*";
                run = "noop";
              }
              {
                url = "/run/media/${config.home.username}/**/*";
                run = "noop";
              }
            ];
            prepend_previewers = [
              # Allow to preview folder
              {
                name = "*/";
                run = "folder";
              }
              # Preview text files
              {
                mime = "{text/*,application/x-subrip}";
                run = "code";
              }
              # Do not preview files in mounted locations
              {
                name = "/run/user/1000/gvfs/**/*";
                run = "noop";
              }
              {
                name = "/run/media/${config.home.username}/**/*";
                run = "noop";
              }
            ];
          };

          keymap.mgr.prepend_keymap = [
            {
              on = ["M" "m"];
              run = "plugin gvfs -- select-then-mount";
              desc = "Select device to mount";
            }
            {
              on = ["M" "u"];
              run = "plugin gvfs -- select-then-unmount --eject";
              desc = "Select device then eject";
            }
            {
              on = ["M" "U"];
              run = "plugin gvfs -- select-then-unmount --eject --force";
              desc = "Select device then force to eject/unmount";
            }
            {
              on = ["M" "a"];
              run = "plugin gvfs -- add-mount";
              desc = "Add a GVFS mount URI";
            }
            {
              on = ["M" "e"];
              run = "plugin gvfs -- edit-mount";
              desc = "Edit a GVFS mount URI";
            }
            {
              on = ["M" "r"];
              run = "plugin gvfs -- remove-mount";
              desc = "Remove a GVFS mount URI";
            }
            {
              on = ["g" "m"];
              run = "plugin gvfs -- jump-to-device";
              desc = "Select device to jump to its mount point";
            }
            {
              on = ["g" "M"];
              run = "plugin gvfs -- jump-back-prev-cwd";
              desc = "Jump back to the position before jumped to device";
            }
          ];
        };
      })

      (mkIf (pkgs ? yaziPlugins && (pkgs.yaziPlugins ? "recycle-bin" && pkgs.yaziPlugins ? restore)) {
        programs.yazi = {
          extraPackages = with pkgs; [trash-cli];

          plugins = {
            inherit (pkgs.yaziPlugins) recycle-bin;
            inherit (pkgs.yaziPlugins) restore;
          };

          initLua = ''
            require("recycle-bin"):setup()
          '';

          keymap.mgr.prepend_keymap = [
            {
              on = ["R" "o"];
              run = "plugin recycle-bin -- open";
              desc = "Open Trash";
            }
            {
              on = ["R" "e"];
              run = "plugin recycle-bin -- empty";
              desc = "Empty Trash";
            }
            {
              on = ["R" "D"];
              run = "plugin recycle-bin -- emptyDays";
              desc = "Empty by days deleted";
            }
            {
              on = ["R" "d"];
              run = "plugin recycle-bin -- delete";
              desc = "Delete from Trash";
            }
            {
              on = ["R" "r"];
              run = "plugin recycle-bin -- restore";
              desc = "Restore from Trash";
            }
            {
              on = ["R" "u"];
              run = "plugin restore -- --interactive --interactive-overwrite";
              desc = "Restore deleted files/folders (Interactive overwrite)";
            }
          ];
        };
      })
    ]);
  }

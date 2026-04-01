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
        type = with types; attrsOf (oneOf [int str bool]);
        default = {};
        description = "The extra settings to inject into yazi";
      };

      plugins = mkOption {
        type = with types; attrsOf (oneOf [path package]);
        default = {};
        description = "The extra plugins to inject into yazi";
      };
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        glib
      ];

      programs.yazi = {
        enable = true;

        initLua = ''
          require("gvfs"):setup({
            password_vault = "keyring",
            save_password_autoconfirm = true
          })
        '';

        settings = {
          plugin = {
            prepend_preloaders = [
              # Do not preload files in mounted locations:
              # Environment variable won't work here.
              # Using absolute path instead.
              {
                url = "/run/user/1000/gvfs/**/*";
                run = "noop";
              }

              # For mounted hard disk/drive
              {
                url = "/run/media/${config.home.username}/**/*";
                run = "noop";
              }
            ];
            prepend_previewers = [
              # Allow to preview folder.
              {
                name = "*/";
                run = "folder";
              }

              # Do not previewing files in mounted locations.
              # Uncomment the line below to allow previewing text files.
              {
                mime = "{text/*,application/x-subrip}";
                run = "code";
              }

              # Using absolute path.
              {
                name = "/run/user/1000/gvfs/**/*";
                run = "noop";
              }

              # For mounted hard disk/drive.
              {
                name = "/run/media/${config.home.username}/**/*";
                run = "noop";
              }
            ];
          };
        };

        keymap = {
          mgr = {
            prepend_keymap = [
              # Mount
              {
                on = ["M" "m"];
                run = "plugin gvfs -- select-then-mount --jump";
                desc = "Select device to mount and jump to its mount point";
              }

              # This will remount device under current working directory (cwd)
              #   -> cwd = /run/user/1000/gvfs/DEVICE_1/FOLDER_A
              #   -> device mountpoint = /run/user/1000/gvfs/DEVICE_1
              #   -> remount this DEVIEC_1 if needed
              {
                on = ["M" "R"];
                run = "plugin gvfs -- remount-current-cwd-device";
                desc = "Remount device under cwd";
              }

              # Or this if you want to unmount and eject device.
              #   -> Ejected device can safely be removed.
              #   -> Ejecting a device will unmount all paritions/volumes under it.
              #   -> Fallback to normal unmount if not supported by device.
              {
                on = ["M" "u"];
                run = "plugin gvfs -- select-then-unmount --eject";
                desc = "Select device then eject";
              }

              # Also support force unmount/eject.
              #   -> Ignore outstanding file operations when unmounting or ejecting
              {
                on = ["M" "U"];
                run = "plugin gvfs -- select-then-unmount --eject --force";
                desc = "Select device then force to eject/unmount";
              }

              # Add Scheme/Mount URI:
              #   -> Available schemes: mtp, gphoto2, smb, sftp, ftp, nfs, dns-sd, dav, davs, dav+sd, davs+sd, afp, afc, sshfs
              #   -> Read more about the schemes here: https://wiki.gnome.org/Projects(2f)gvfs(2f)schemes.html
              #   -> Explain about the scheme:
              #       -> If it shows like this: {ftp,ftps,ftpis}://[user@]host[:port]
              #       -> All of the value within [] is optional. For values within {}, you must choose exactly one. All others are required.
              #       -> empty [user] or "anonymous" user is anonymous user in (ftp)
              #           -> ftp://anonymous@192.168.1.2:9999 -> skip user input step.
              #           -> ftp://192.168.1.2:9999 -> input empty value in user input box.
              #       -> Example: {ftp,ftps,ftpis}://[user@]host[:port] => ip and port: "ftp://myusername@192.168.1.2:9999" or domain: "ftps://myusername@github.com"
              #       -> More examples: smb://user@192.168.1.2/share, smb://WORKGROUP;user@192.168.1.2/share, sftp://user@192.168.1.2/, ftp://192.168.1.2/
              # !WARNING: - Scheme/Mount URI shouldn't contain password.
              #           - Google Drive, One drive are listed automatically via GNOME Online Accounts (GOA). Avoid adding them.
              #           - MTP, GPhoto2, AFC, Hard disk/drive, fstab with x-gvfs-show are also listed automatically. Avoid adding them.
              #           - SSH, SFTP, FTP(s), AFC, DNS_SD now support [/share]. For example: sftp://user@192.168.1.2/home/user_name -> /share = /home/user_name
              #           - ssh:// is alias for sftp://.
              #             -> {sftp,ssh}://[user@]host[:port]. Host can be Host alias in .ssh/config file, ip or domain.
              #             -> For example (home is Host alias in .ssh/config file: Host home):
              #                  -> ssh://user_name@home/home/user_name -> this will mount root path, but jump to subfolder /home/user_name
              #                  -> sftp://user_name@192.168.1.2/home/user_name -> same as above but with ip
              #                  -> sftp://user_name@192.168.1.2:9999/home/user_name -> same as above but with ip and port
              {
                on = ["M" "a"];
                run = "plugin gvfs -- add-mount";
                desc = "Add a GVFS mount URI";
              }

              # Edit a Scheme/Mount URI
              #   -> Will clear saved passwords for that mount URI.
              {
                on = ["M" "e"];
                run = "plugin gvfs -- edit-mount";
                desc = "Edit a GVFS mount URI";
              }

              # Remove a Scheme/Mount URI
              #   -> Will clear saved passwords for that mount URI.
              {
                on = ["M" "r"];
                run = "plugin gvfs -- remove-mount";
                desc = "Remove a GVFS mount URI";
              }

              # Jump
              # If you use `x-systemd.automount` in /etc/fstab or manually added automount unit,
              # then you can use `--automount` argument to auto mount device before jump.
              # Otherwise it won't show up in the jump list.
              {
                on = ["g" "m"];
                run = "plugin gvfs -- jump-to-device";
                desc = "Select device to jump to its mount point";
              }
              {
                on = ["`" "`"];
                run = "plugin gvfs -- jump-back-prev-cwd";
                desc = "Jump back to the position before jumped to device";
              }

              # Automount (This is different from `x-systemd.automount` in /etc/fstab)
              #   -> Hover over any file/folder under a mounted device then run `automount-when-cd` action to enable automount when cd/jump for that device.
              #   -> When you cd/jump to unmounted device mountpoint or its sub folder, this will auto-mount the device before jump.
              #   -> Works with any command or any bookmark plugin that change cwd. For example, use `yamb` to add bookmarks and jump to them, use yazi's built-in `cd` `back` `forward` commands:

              #   -> { on = [ "m", "a" ], run = [ "plugin yamb -- save", "plugin gvfs -- automount-when-cd" ], desc = "Add bookmark and enable automount when cd"}
              {
                on = ["M" "t"];
                run = "plugin gvfs -- automount-when-cd";
                desc = "Enable automount when cd to device under cwd";
              }
              {
                on = ["M" "T"];
                run = "plugin gvfs -- automount-when-cd --disabled";
                desc = "Disable automount when cd to device under cwd";
              }
            ];
          };
        };

        plugins =
          {
            inherit (pkgs.yaziPlugins) gvfs;
          }
          // cfg.plugins;
      };
    };
  }

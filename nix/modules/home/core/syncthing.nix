{
  lib,
  config,
  ...
}: let
  cfg = config.core.syncthing;

  deviceSubmodule = _: {
    options = {
      id = lib.mkOption {
        type = lib.types.str;
        description = "Syncthing device ID (44 or 52-character base32 key).";
      };

      name = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional friendly display name for the device.";
      };

      addresses = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of network addresses or hostnames for the device.";
        example = ["tcp://192.168.1.50:22000" "dynamic"];
      };
    };
  };

  folderSubmodule = _: {
    options = {
      path = lib.mkOption {
        type = lib.types.str;
        description = "Absolute path to the synchronized folder.";
      };

      id = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Folder ID string used by Syncthing. Defaults to folder attribute name if null.";
      };

      label = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Friendly display label for the folder in the GUI.";
      };

      devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of device names (from core.syncthing.devices) that share this folder.";
      };

      ignorePerms = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether Syncthing should ignore file permissions when syncing.";
      };
    };
  };
in
  with lib; {
    options.core.syncthing = {
      enable = mkEnableOption "Syncthing user directory synchronization";

      sharedDir = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/Shared";
        description = "Path to the primary Shared directory to synchronize.";
        example = "/home/user/Shared";
      };

      gui = {
        address = mkOption {
          type = types.str;
          default = "127.0.0.1:8384";
          description = "Address for the Syncthing web GUI.";
          example = "0.0.0.0:8384";
        };
      };

      tray = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable the syncthing tray application service.";
        };
      };

      devices = mkOption {
        type = types.attrsOf (types.submodule deviceSubmodule);
        default = {};
        description = "Attrset of paired Syncthing devices.";
        example = {
          ares = {
            id = "AAAAAAA-BBBBBBB-CCCCCC-DDDDDDD-EEEEEEE-FFFFFF-GGGGGGG-HHHHHHH";
          };
        };
      };

      extraFolders = mkOption {
        type = types.attrsOf (types.submodule folderSubmodule);
        default = {};
        description = "Additional folders to synchronize beyond the default Shared folder.";
      };
    };

    config = mkIf cfg.enable {
      services.syncthing = {
        enable = true;
        guiAddress = cfg.gui.address;

        tray.enable = cfg.tray.enable;

        settings = {
          devices =
            mapAttrs (
              _name: device:
                filterAttrs (_: v: v != null) {
                  inherit (device) id;
                  name =
                    if device.name != null
                    then device.name
                    else null;
                  addresses =
                    if device.addresses != []
                    then device.addresses
                    else null;
                }
            )
            cfg.devices;

          folders = mkMerge [
            {
              "Shared" = {
                path = cfg.sharedDir;
                id = "shared-folder";
                label = "Shared Directory";
                devices = builtins.attrNames cfg.devices;
                ignorePerms = true;
              };
            }
            (mapAttrs (
                name: folder:
                  filterAttrs (_: v: v != null) {
                    inherit (folder) path ignorePerms devices;
                    id =
                      if folder.id != null
                      then folder.id
                      else name;
                    label =
                      if folder.label != null
                      then folder.label
                      else name;
                  }
              )
              cfg.extraFolders)
          ];
        };
      };

      systemd.user.tmpfiles.rules = [
        "d ${cfg.sharedDir} 0755 - - -"
      ];
    };
  }

{
  lib,
  pkgs,
  self,
  inputs,
  ...
}: let
  pkgs' =
    lib.mapAttrs' (
      name: _: {
        name = lib.removeSuffix ".nix" name;
        value = import (./. + "/${name}") {inherit lib pkgs self inputs;};
      }
    ) (
      lib.filterAttrs (
        name: type:
          (type == "directory" && builtins.pathExists (./. + "/${name}/default.nix"))
          || (type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name)
      ) (builtins.readDir ./.)
    );
in
  pkgs'
  // (
    lib.mapAttrs' (name: hostConfig: {
      name = "${name}-vm";
      value =
        (hostConfig.extendModules {
          modules = [
            {
              # Ensure we don't conflict with the system's own filesystem or bootloader config
              # as the image generator will provide its own.
              # We use mkOverride 0 to ensure these win over ANY other definition.
              disko.enableConfig = lib.mkOverride 0 false;
              boot.loader = {
                grub.enable = lib.mkOverride 0 false;
                systemd-boot.enable = lib.mkOverride 0 false;
                generic-extlinux-compatible.enable = lib.mkOverride 0 false;
              };

              # The image generator usually sets up / but if it still conflicts,
              # this override helps.
              fileSystems."/" = lib.mkOverride 0 {
                device = "/dev/vda";
                fsType = "ext4";
              };
            }
          ];
        }).config.system.build.images.qemu;
    }) (lib.filterAttrs (_name: hostConfig: hostConfig.pkgs.system == pkgs.system) self.nixosConfigurations)
  )

# Shim exposing every nixosConfiguration as a runnable QEMU VM.
#
#   nix run .#vm-<host>
#
# Each host is re-evaluated via `extendModules` with the qemu-vm module and
# overrides that strip out hardware-specific pieces (disko disk layout, LUKS,
# EFI variable writes). The real host configuration is untouched.
{ config, lib, ... }:
{
  perSystem =
    { system, ... }:
    let
      hosts = lib.filterAttrs (
        _: host: host.pkgs.stdenv.hostPlatform.system == system
      ) config.flake.nixosConfigurations;

      mkVm =
        _name: host:
        let
          vm = host.extendModules {
            modules = [
              (
                { modulesPath, ... }:
                {
                  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

                  # qemu-vm provides its own disk/filesystems; drop disko's
                  # real-hardware layout (partitions, LUKS, mounts).
                  disko.enableConfig = lib.mkForce false;

                  # The facter report describes the physical machine (nvidia,
                  # amdgpu, nvme, ...); none of that exists in the guest.
                  hardware.facter.reportPath = lib.mkForce null;

                  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

                  # The guest generates its own SSH host key, which is not a
                  # sops recipient, so the real secrets can't be decrypted.
                  # Use a throwaway password instead.
                  sops.secrets = lib.mkForce { };
                  users.users.sphoono = {
                    hashedPasswordFile = lib.mkForce null;
                    initialPassword = "vm";
                  };

                  virtualisation = {
                    memorySize = lib.mkDefault 4096;
                    cores = lib.mkDefault 4;
                    diskSize = lib.mkDefault 20480;
                  };
                }
              )
            ];
          };
        in
        vm.config.system.build.vm.overrideAttrs (old: {
          meta = (old.meta or { }) // {
            # qemu-vm names the script after the guest's hostname.
            mainProgram = "run-${vm.config.networking.hostName}-vm";
          };
        });
    in
    {
      packages = lib.mapAttrs' (name: host: lib.nameValuePair "vm-${name}" (mkVm name host)) hosts;
    };
}

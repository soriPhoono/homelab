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
          # Users come from the real host, so the overrides below fit
          # whichever users a host defines.
          userNames = builtins.attrNames host.config.home-manager.users;
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
                  # QEMU's default display is Bochs-compatible VGA ("-vga
                  # std"); without its KMS driver in the initrd there's no
                  # framebuffer for plymouth to render on, so it silently
                  # falls back to plain systemd status text.
                  boot.initrd.availableKernelModules = [ "bochs" ];
                  # The guest generates its own SSH host key, which is not a
                  # sops recipient, so the real secrets can't be decrypted.
                  # Use a throwaway password instead.
                  sops.secrets = lib.mkForce { };
                  users.users = lib.genAttrs userNames (_: {
                    hashedPasswordFile = lib.mkForce null;
                    initialPassword = "vm";
                  });
                  virtualisation = {
                    # The writable store overlay lives on tmpfs but the Nix DB
                    # lives on the disk image; a persisted image therefore
                    # lists .drv files that no longer exist on the next boot.
                    # Boot stateless so every run starts from a clean DB.
                    diskImage = null;
                    memorySize = lib.mkDefault (4096 * 2);
                    cores = lib.mkDefault (4 * 2);
                    diskSize = lib.mkDefault (20480 * 2);
                  };
                  # Home Manager's activation only waits on nix-daemon.socket,
                  # not the daemon actually being ready. On real hardware the
                  # daemon wins that race easily; over this VM's slower
                  # overlayfs-on-virtiofs writable store it sometimes doesn't,
                  # and `nix-env -i` fails opening a `.drv` it just
                  # instantiated. Wait on the real service and retry once.
                  systemd.services = lib.genAttrs (map (user: "home-manager-${user}") userNames) (_: {
                    after = [ "nix-daemon.service" ];
                    serviceConfig = {
                      Restart = "on-failure";
                      RestartSec = 2;
                    };
                  });
                  services = {
                    qemuGuest.enable = true;
                    spice-vdagentd.enable = true;
                    # Debugging access: the host's own compositor swallows
                    # global shortcuts (SUPER, Ctrl+Alt+Fn) before they ever
                    # reach the guest window, so there's no reliable way to
                    # get a shell through the display. SSH in instead.
                    openssh = {
                      enable = true;
                      settings.PasswordAuthentication = lib.mkForce true;
                    };
                  };
                  virtualisation.forwardPorts = [
                    {
                      from = "host";
                      host.port = 2222;
                      guest.port = 22;
                    }
                  ];
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

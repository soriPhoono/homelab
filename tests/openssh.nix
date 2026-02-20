{
  pkgs,
  ...
}:
pkgs.nixosTest {
  name = "openssh-security";

  nodes.machine = { ... }: {
    imports = [ ../modules/nixos/core/networking/openssh.nix ];

    # Minimal configuration to make the VM bootable
    boot.loader.grub.enable = false;
    fileSystems."/" = {
      device = "/dev/vda";
      fsType = "ext4";
    };

    # We need this for the system to boot in a VM test
    system.stateVersion = "24.11";
  };

  testScript = ''
    machine.wait_for_unit("sshd.service")

    with subtest("Verify security settings"):
        # sshd -T outputs the effective configuration
        machine.succeed("sshd -T | grep -i 'permitrootlogin no'")
        machine.succeed("sshd -T | grep -i 'passwordauthentication no'")
        machine.succeed("sshd -T | grep -i 'kbdinteractiveauthentication no'")
        machine.succeed("sshd -T | grep -i 'usedns yes'")
  '';
}

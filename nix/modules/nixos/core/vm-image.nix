{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.vm-image;
in
  with lib; {
    options.core.vm-image = {
      enable = mkEnableOption "Build this system as a QEMU qcow2 VM image (overrides hardware configs)";
    };

    config = mkIf cfg.enable {
      # --- Override filesystems (disko provides real-hardware ones) ---
      fileSystems = mkForce {
        "/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
          autoResize = true;
        };
        "/boot" = {
          device = "/dev/disk/by-label/ESP";
          fsType = "vfat";
        };
      };

      # --- Override boot loader ---
      boot.loader.grub.enable = mkForce false;
      boot.loader.systemd-boot.enable = mkForce true;
      boot.loader.efi.canTouchEfiVariables = mkForce true;
      boot.growPartition = mkDefault true;

      # --- Disable LUKS (disko may set this) ---
      boot.initrd.luks.devices = mkForce {};

      # --- VM guest support ---
      services.qemuGuest.enable = true;
      boot.initrd.availableKernelModules = [
        "virtio_pci"
        "virtio_blk"
        "virtio_scsi"
        "virtio_net"
      ];

      # --- Generic GPU for VM ---
      services.xserver.videoDrivers = mkForce ["modesetting"];

      # --- Disable homelab hardware that doesn't apply to VMs ---
      core.boot.enable = mkForce false;
      core.hardware.gpu.enable = mkForce false;
      core.hardware.gpu.amd.enable = mkForce false;
      core.hardware.gpu.intel.enable = mkForce false;
      core.hardware.gpu.nvidia.enable = mkForce false;
      core.hardware.hid.keyboards.enable = mkForce false;
      core.hardware.hid.logitech.enable = mkForce false;
      core.hardware.hid.tablet.enable = mkForce false;
      core.hardware.hid.xbox_controllers.enable = mkForce false;
      core.hardware.adb.enable = mkForce false;
      core.hardware.bluetooth.enable = mkForce false;
      core.hardware.cpu.enable = mkForce false;

      # --- Sane VM disk size ---
      virtualisation.diskSize = 20 * 1024; # 20GB

      # --- Build the qcow2 image ---
      system.build.image = import (pkgs.path + "/nixos/lib/make-disk-image.nix") {
        inherit lib config pkgs;
        format = "qcow2";
        partitionTableType = "efi";
        onlyNixStore = false;
        installBootLoader = true;
        touchEFIVars = true;
        diskSize = "auto";
        additionalSpace = "0M";
        copyChannel = false;
      };
    };
  }

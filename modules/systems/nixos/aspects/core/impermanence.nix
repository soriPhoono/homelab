/**
  Impermanence: the root subvolume is deleted and recreated empty in the
  initrd on every boot, so a host starts each boot from its configuration
  alone. Nothing of the previous root is kept.

  What survives a reboot:

  - `/nix`, `/home` and `/boot`, which are filesystems of their own. All of
    `/home` is kept, so user data needs no declaration.
  - Every path declared under `environment.persistence."/persist"`, which is
    bind-mounted from the `/persist` subvolume.

  Aspects declare the state they own next to the service that writes it:

  ```nix
  environment.persistence."/persist".directories = [ "/var/lib/foo" ];
  ```

  The module behind that option is imported on every host and stays inert
  until a host includes this aspect, so those declarations cost nothing
  elsewhere.

  A host that includes this aspect needs a btrfs root mounted from a named
  subvolume and a `/persist` filesystem. The host disko layouts add the
  `/persist` subvolume once the aspect is included, which means the host has
  to be reinstalled from that layout: an installed host has no such
  subvolume and would fail to mount it.

  Before the first boot of a reinstalled host, put its SSH host key at
  `/persist/etc/ssh/ssh_host_ed25519_key` (`/mnt/persist/...` from the
  installer). sops decrypts with that key, and with immutable users a host
  that cannot decrypt has no login password. Reusing the old key keeps the
  host's age recipient, so no secret needs re-encrypting.
*/
{ inputs, lib, ... }:
let
  persist = "/persist";
in
{
  flake-file.inputs.impermanence = {
    url = "github:nix-community/impermanence";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      home-manager.follows = "home-manager";
    };
  };

  den.default.nixos = {
    imports = [ inputs.impermanence.nixosModules.impermanence ];
    environment.persistence.${persist} = {
      enable = lib.mkDefault false;
      hideMounts = true;
    };
  };

  den.aspects.core.impermanence.nixos =
    { config, utils, ... }:
    let
      cfg = config.environment.persistence.${persist};
      root = config.fileSystems."/";

      # The subvolume to reset is whichever one the host mounts as root.
      subvolOptions = lib.filter (lib.hasPrefix "subvol=") root.options;
      subvolume =
        if subvolOptions == [ ] then
          ""
        else
          lib.removePrefix "/" (lib.removePrefix "subvol=" (lib.head subvolOptions));
      # Mount the top level the way root is mounted, minus what selects root.
      mountOptions = [
        "subvolid=5"
      ]
      ++ lib.filter (o: !(lib.hasPrefix "subvol=" o || lib.hasPrefix "x-" o)) root.options;

      device = "${utils.escapeSystemdPath root.device}.device";
      top = "/run/wipe-root";

      hostKeys =
        lib.optionals config.services.openssh.enable (map (k: k.path) config.services.openssh.hostKeys)
        ++ [ sopsKey ];
      sopsKey = "/etc/ssh/ssh_host_ed25519_key";
    in
    {
      environment.persistence.${persist} = {
        enable = true;

        directories = [
          "/var/log"
          # uid/gid and subuid/subgid allocations; without it file ownership
          # under /persist and /home drifts between boots.
          "/var/lib/nixos"
          # Timer stamps, the random seed, linger, backlight and rfkill state.
          "/var/lib/systemd"
        ]
        # State of nixpkgs services that no aspect here owns, usually because
        # a desktop environment switches them on.
        ++ lib.optional config.services.fwupd.enable "/var/lib/fwupd"
        ++ lib.optional config.services.fprintd.enable {
          directory = "/var/lib/fprint";
          mode = "0700";
        }
        ++ lib.optional config.services.upower.enable "/var/lib/upower"
        ++ lib.optional config.services.power-profiles-daemon.enable "/var/lib/power-profiles-daemon"
        ++ lib.optional config.services.accounts-daemon.enable "/var/lib/AccountsService";

        files = [
          "/etc/machine-id"
        ]
        ++ lib.concatMap (key: [
          key
          "${key}.pub"
        ]) (lib.unique hostKeys);
      };

      # Everything below follows `enable` rather than the aspect, so the VM
      # shim, which has no btrfs disk to reset, can switch it all off at once.
      assertions = lib.mkIf cfg.enable [
        {
          assertion = root.fsType == "btrfs" && subvolume != "";
          message = ''
            core.impermanence resets the root subvolume, so `/` must be btrfs
            mounted with a `subvol=<name>` option.
          '';
        }
        {
          assertion = !config.users.mutableUsers;
          message = ''
            core.impermanence discards /etc/passwd and /etc/shadow on every
            boot, so users must be declarative: set
            `users.mutableUsers = false`.
          '';
        }
      ];

      fileSystems.${persist} = lib.mkIf cfg.enable { neededForBoot = true; };

      # Secrets for users are decrypted before the bind mounts over /etc
      # exist, so read the keys from where they are stored instead.
      sops = lib.mkIf cfg.enable {
        age.sshKeyPaths = lib.mkForce [ "${persist}${sopsKey}" ];
        gnupg.sshKeyPaths = lib.mkForce (
          map (key: "${persist}${key.path}") (
            lib.filter (key: key.type == "rsa") (
              lib.optionals config.services.openssh.enable config.services.openssh.hostKeys
            )
          )
        );
      };

      boot.initrd.systemd.services.wipe-root = lib.mkIf cfg.enable {
        description = "Recreate the root subvolume empty";
        wantedBy = [ "initrd.target" ];
        requires = [ device ];
        after = [
          device
          # A resumed image still has the old root mounted; never reset the
          # subvolume underneath it.
          "systemd-hibernate-resume.service"
        ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = false;
        serviceConfig.Type = "oneshot";
        script = ''
          mkdir -p ${top}
          mount -t btrfs -o ${lib.concatStringsSep "," mountOptions} ${lib.escapeShellArg root.device} ${top}
          trap 'umount ${top}' EXIT

          # --recursive also removes subvolumes nested in root, which a plain
          # delete refuses to do.
          if [ -e ${top}/${lib.escapeShellArg subvolume} ]; then
            btrfs subvolume delete --recursive ${top}/${lib.escapeShellArg subvolume}
          fi
          btrfs subvolume create ${top}/${lib.escapeShellArg subvolume}
        '';
      };
    };
}

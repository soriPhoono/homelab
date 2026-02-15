# Comprehensive NixOS build test for KDE desktop configuration.
#
# This test builds a dummy NixOS system that exhaustively exercises both the
# `core` and `desktop` module trees, plus home-manager integration — without
# any hardware-specific drivers (GPU, asusd).
#
# The test is a derivation: `nix flake check` will force evaluation of the
# entire NixOS configuration, catching type errors, missing options, and
# module conflicts at eval time.
{
  pkgs,
  inputs,
  self,
  ...
}: let
  inherit (inputs.nixpkgs) lib;

  hostName = "test-kde-desktop";

  # Mirror the same home-manager shared module stack from flake.nix
  homeManagerModules = with inputs; [
    self.homeModules.default
    sops-nix.homeManagerModules.sops
    nvf.homeManagerModules.default
    mcps.homeManagerModules.gemini-cli
    mcps.homeManagerModules.claude
  ];

  # ================================================================
  # Build the dummy NixOS configuration
  # ================================================================
  testSystem = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs self hostName;
    };
    modules = with inputs; [
      # --- Flake module imports (mirrors flake.nix nixosModules) --- #
      self.nixosModules.default
      home-manager.nixosModules.home-manager
      nixos-facter-modules.nixosModules.facter
      disko.nixosModules.disko
      determinate.nixosModules.default
      lanzaboote.nixosModules.lanzaboote
      sops-nix.nixosModules.sops
      comin.nixosModules.comin
      nix-index-database.nixosModules.nix-index

      # --- Home Manager wiring --- #
      {
        nixpkgs.overlays = builtins.attrValues self.overlays;
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {inherit inputs self hostName;};
          sharedModules = homeManagerModules;
        };
      }

      # --- Dummy system configuration under test --- #
      ({pkgs, ...}: {
        nixpkgs.config.allowUnfree = true;

        # Minimal filesystem to satisfy NixOS module assertions
        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };

        # ========================================
        # Core Modules
        # ========================================
        core = {
          boot = {
            enable = true;
            plymouth.enable = true;
          };

          networking = {
            network-manager.enable = true;
            tailscale.enable = true;
          };

          # Hardware peripherals — no GPU drivers, no facter report
          hardware = {
            bluetooth.enable = true;
            adb.enable = true;
            hid = {
              logitech.enable = true;
              qmk.enable = true;
              tablet.enable = true;
              xbox_controllers.enable = true;
            };
          };

          gitops = {
            enable = true;
            repo = "https://github.com/test/homelab.git";
            name = "test-kde-desktop";
          };

          # Secrets disabled — needs real sops key material
          # secrets.enable remains false (default)

          users = {
            testuser = {
              admin = true;
              shell = pkgs.fish;
              hashedPassword = "$6$rounds=1000$test$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
              publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyForNixOSBuildTest00000000000000000000";
            };
          };
        };

        # ========================================
        # Desktop Modules
        # ========================================
        desktop = {
          environments.kde.enable = true;

          features = {
            gaming.enable = true;
            printing.enable = true;
            virtualisation.enable = true;
          };

          # asusd deliberately excluded (ASUS-specific hardware)
        };

        # ========================================
        # Home Manager Integration
        # ========================================
        home-manager.users.testuser = {
          core = {
            shells.fish.enable = true;

            git = {
              userName = "Test User";
              userEmail = "test@example.com";
            };

            ssh.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyForNixOSBuildTest00000000000000000000";
          };

          desktop.enable = true;

          userapps = {
            enable = true;

            browsers = {
              firefox.enable = true;
              librewolf.enable = true;
            };

            development = {
              editors = {
                vscode.enable = true;
                neovim.enable = true;
              };
              terminal = {
                ghostty.enable = true;
                kitty.enable = true;
              };
            };
          };
        };
      })
    ];
  };

  # ================================================================
  # Extract evaluated config for assertions
  # ================================================================
  cfg = testSystem.config;
  hmCfg = cfg.home-manager.users.testuser;

  # ================================================================
  # Assertions — validated at Nix evaluation time via nixtest
  # ================================================================
  assertions = [
    # --- Core ---
    {
      name = "Hostname is set correctly";
      actual = cfg.networking.hostName;
      expected = hostName;
    }
    {
      name = "Timezone is managed by automatic-timezoned";
      actual = cfg.time.timeZone;
      expected = null;
    }
    {
      name = "ZRAM swap is enabled";
      actual = cfg.zramSwap.enable;
      expected = true;
    }
    {
      name = "Fish shell is enabled system-wide";
      actual = cfg.programs.fish.enable;
      expected = true;
    }
    {
      name = "OpenSSH is enabled";
      actual = cfg.services.openssh.enable;
      expected = true;
    }
    {
      name = "Nix flakes enabled";
      actual = builtins.elem "flakes" (lib.splitString " " cfg.nix.settings.experimental-features);
      expected = true;
    }

    # --- Networking ---
    {
      name = "NetworkManager is enabled";
      actual = cfg.networking.networkmanager.enable;
      expected = true;
    }
    {
      name = "Tailscale is enabled";
      actual = cfg.services.tailscale.enable;
      expected = true;
    }
    {
      name = "nftables is enabled";
      actual = cfg.networking.nftables.enable;
      expected = true;
    }

    # --- Hardware peripherals ---
    {
      name = "Bluetooth is enabled";
      actual = cfg.hardware.bluetooth.enable;
      expected = true;
    }
    {
      name = "Logitech wireless is enabled";
      actual = cfg.hardware.logitech.wireless.enable;
      expected = true;
    }
    {
      name = "QMK keyboard support is enabled";
      actual = cfg.hardware.keyboard.qmk.enable;
      expected = true;
    }

    # --- Desktop ---
    {
      name = "KDE Plasma 6 is enabled";
      actual = cfg.services.desktopManager.plasma6.enable;
      expected = true;
    }
    {
      name = "PipeWire is enabled";
      actual = cfg.services.pipewire.enable;
      expected = true;
    }
    {
      name = "Flatpak is enabled";
      actual = cfg.services.flatpak.enable;
      expected = true;
    }
    {
      name = "Printing (CUPS) is enabled";
      actual = cfg.services.printing.enable;
      expected = true;
    }
    {
      name = "Libvirtd virtualisation is enabled";
      actual = cfg.virtualisation.libvirtd.enable;
      expected = true;
    }
    {
      name = "Geoclue2 is enabled";
      actual = cfg.services.geoclue2.enable;
      expected = true;
    }
    {
      name = "Comin GitOps is enabled";
      actual = cfg.services.comin.enable;
      expected = true;
    }
    {
      name = "Wayland Ozone enabled for Electron apps";
      actual = cfg.environment.sessionVariables.NIXOS_OZONE_WL;
      expected = "1";
    }

    # --- User ---
    {
      name = "Test user exists";
      actual = cfg.users.extraUsers ? testuser;
      expected = true;
    }
    {
      name = "Test user is in wheel group";
      actual = builtins.elem "wheel" cfg.users.extraUsers.testuser.extraGroups;
      expected = true;
    }
    {
      name = "Test user shell is fish";
      actual = cfg.users.extraUsers.testuser.shell.pname;
      expected = "fish";
    }
    {
      name = "Test user is in libvirtd group";
      actual = builtins.elem "libvirtd" cfg.users.extraUsers.testuser.extraGroups;
      expected = true;
    }
    {
      name = "Test user is in networkmanager group";
      actual = builtins.elem "networkmanager" cfg.users.extraUsers.testuser.extraGroups;
      expected = true;
    }

    # --- Home Manager ---
    {
      name = "Home Manager is configured for testuser";
      actual = cfg.home-manager.users ? testuser;
      expected = true;
    }
    {
      name = "HM: git is enabled";
      actual = hmCfg.programs.git.enable;
      expected = true;
    }
    {
      name = "HM: git username is set";
      actual = hmCfg.programs.git.settings.user.name;
      expected = "Test User";
    }
    {
      name = "HM: SSH is enabled";
      actual = hmCfg.programs.ssh.enable;
      expected = true;
    }
    {
      name = "HM: fish is enabled";
      actual = hmCfg.programs.fish.enable;
      expected = true;
    }
    {
      name = "HM: Firefox is enabled";
      actual = hmCfg.programs.firefox.enable;
      expected = true;
    }
    {
      name = "HM: fontconfig enabled";
      actual = hmCfg.fonts.fontconfig.enable;
      expected = true;
    }
    {
      name = "HM: direnv is enabled";
      actual = hmCfg.programs.direnv.enable;
      expected = true;
    }
    {
      name = "HM: btop is enabled";
      actual = hmCfg.programs.btop.enable;
      expected = true;
    }
    {
      name = "HM: VSCode is enabled";
      actual = hmCfg.programs.vscode.enable;
      expected = true;
    }
    {
      name = "HM: kitty is enabled";
      actual = hmCfg.programs.kitty.enable;
      expected = true;
    }
    {
      name = "HM: starship is enabled";
      actual = hmCfg.programs.starship.enable;
      expected = true;
    }
    {
      name = "HM: eza is enabled";
      actual = hmCfg.programs.eza.enable;
      expected = true;
    }
    {
      name = "HM: delta is enabled";
      actual = hmCfg.programs.delta.enable;
      expected = true;
    }
    {
      name = "HM: home-manager self-managed";
      actual = hmCfg.programs.home-manager.enable;
      expected = true;
    }
  ];

  # Validate assertions at eval time by checking each one
  assertionReport = let
    failures = builtins.filter (t: t.actual != t.expected) assertions;
    numTests = builtins.length assertions;
    numFailed = builtins.length failures;
    failureMsg = builtins.concatStringsSep "\n" (
      map (t: "  [FAIL] ${t.name}\n    Got:      ${builtins.toJSON t.actual}\n    Expected: ${builtins.toJSON t.expected}") failures
    );
  in
    if numFailed == 0
    then "[PASS] ${toString numTests}/${toString numTests} assertions passed"
    else throw "${toString numFailed}/${toString numTests} assertions failed:\n${failureMsg}";
in
  # Produce a derivation for `nix flake check`.
  # The assertion report above is strict — evaluation aborts on failure
  # before reaching this runCommand. On success, we force evaluation of
  # system.build.toplevel (the full NixOS system closure).
  pkgs.runCommand "kde-desktop-test" {} ''
    echo "NixOS KDE Desktop Integration Test"
    echo "==================================="
    echo "${assertionReport}"
    echo ""
    echo "System toplevel: ${cfg.system.build.toplevel}"
    echo "All tests passed!"
    touch $out
  ''

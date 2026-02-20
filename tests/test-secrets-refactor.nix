{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib, ... }:
let
  eval = lib.evalModules {
    modules = [
      ../modules/nixos/core/secrets.nix
      {
        # Mock dependencies
        options.core.users = lib.mkOption { type = lib.types.attrs; default = {}; };
        options.home-manager.users = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
                options.core.secrets.enable = lib.mkEnableOption "secrets";
            });
            default = {};
        };
        options.services.openssh.hostKeys = lib.mkOption { default = []; type = lib.types.listOf lib.types.attrs; };
        options.systemd.tmpfiles.rules = lib.mkOption { type = lib.types.listOf lib.types.str; };
        options.sops = lib.mkOption { type = lib.types.attrs; default = {}; };

        # Config
        core.secrets.enable = true;
        core.users = {
            alice = {};
            bob = {};
        };
        home-manager.users.alice.core.secrets.enable = true;
        home-manager.users.bob.core.secrets.enable = false;
      }
    ];
  };
in
  pkgs.runCommand "test-secrets-refactor" {} ''
    echo "Checking evaluation..."
    # alice should have secrets, bob should not.
    # systemd.tmpfiles.rules should have entries for alice.

    rules="${toString eval.config.systemd.tmpfiles.rules}"
    echo "Generated rules: $rules"
    if [[ "$rules" != *"alice"* ]]; then
        echo "Alice missing from tmpfiles rules"
        exit 1
    fi
    if [[ "$rules" == *"bob"* ]]; then
        echo "Bob present in tmpfiles rules (should be absent)"
        exit 1
    fi

    # Check sops secrets
    # sops.secrets should have entries for alice
    secrets="${toString (builtins.attrNames eval.config.sops.secrets)}"
    echo "Generated secrets keys: $secrets"
    if [[ "$secrets" != *"users/alice/age_key"* ]]; then
        echo "Alice missing from sops secrets"
        exit 1
    fi
     if [[ "$secrets" == *"bob"* ]]; then
        echo "Bob present in sops secrets (should be absent)"
        exit 1
    fi

    touch $out
  ''

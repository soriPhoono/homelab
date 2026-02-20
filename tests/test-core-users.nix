{ pkgs, lib, self, ... }:

let
  hostName = "test-host";

  # Stub for self
  mockSelf = self;

  testSystem = lib.nixosSystem {
    inherit pkgs;
    specialArgs = {
      inherit hostName;
      self = mockSelf;
      inherit lib;
    };
    modules = [
      ../modules/nixos/core/users.nix
      ({ config, ... }: {
        # Minimal config to make evaluation work
        fileSystems."/".device = "/dev/null";
        boot.loader.grub.enable = false;
        system.stateVersion = "24.05";

        # Configure the module
        core.users.testuser = {
          subUidRanges = [ { startUid = 1000; count = 1; } ];
          subGidRanges = [ { startGid = 2000; count = 1; } ];
        };
      })
    ];
  };

  cfg = testSystem.config.core.users.testuser;
in
pkgs.runCommand "test-core-users" {
  nativeBuildInputs = [ pkgs.jq ];
} ''
  echo "Checking subUidRanges..."
  uid=$(echo '${builtins.toJSON cfg.subUidRanges}' | jq '.[0].startUid')
  if [ "$uid" != "1000" ]; then
    echo "Expected startUid 1000, got $uid"
    exit 1
  fi

  echo "Checking subGidRanges..."
  gid=$(echo '${builtins.toJSON cfg.subGidRanges}' | jq '.[0].startGid')
  if [ "$gid" != "2000" ]; then
    echo "Expected startGid 2000, got $gid"
    exit 1
  fi

  echo "All checks passed."
  touch $out
''

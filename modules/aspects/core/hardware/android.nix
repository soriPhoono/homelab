{
  den.aspects.core.hardware.android = {
    nixos = { pkgs, config, ... }: {
      environment.systemPackages = with pkgs; [
        android-tools
      ];

      users.groups.adbusers.members = config.users.groups.wheel.members;
    };
  };
}

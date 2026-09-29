{
  den.aspects.core.hardware.android = {
    nixos = { config, ... }: {
      users.groups.adbusers.members = config.users.groups.wheel.members;
    };
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        android-tools
      ];
    };
  };
}

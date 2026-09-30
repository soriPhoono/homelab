{ den, ... }: {
  den.aspects.sphoono = {
    includes = [
      (den.batteries.user-shell "fish")
    ];
    nixos.users.users.sphoono.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsLDpds7sJGuczBvZEIkqEBwjdk22MbiML/WYzHwzkT Personal Key"
    ];
    homeManager.programs.nh.enable = true;
  };
}

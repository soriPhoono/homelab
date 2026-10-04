{ den, ... }: {
  den.aspects.spookyskelly = {
    includes = [
      (den.batteries.user-shell "fish")
    ];
    nixos.users.users.spookyskelly = {
      description = "Spooky Skelly";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEe5elK6ZPxVfoUBM1Ytd9/15OjdTeIfyUU61qR3osP8"
      ];
      linger = true;
    };
  };
}

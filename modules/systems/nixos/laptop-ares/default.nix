{ den, ... }: {
  imports = [
    ./disko.nix
  ];

  den.hosts.x86_64-linux.laptop-ares.users.sphoono = { };

  den.aspects.laptop-ares.nixos.hardware.facter.reportPath = ./facter.json;

  den.aspects.sphoono = {
    includes = [ den.batteries.primary-user ];
    nixos =
      { config, ... }:
      {
        sops.secrets."users/sphoono/password" = {
          sopsFile = ../../../../secrets/laptop-ares.yaml;
          # Decrypted early enough for user creation.
          neededForUsers = true;
        };
        # `or null` lets vm.nix drop the secret without breaking evaluation.
        users.users.sphoono.hashedPasswordFile = config.sops.secrets."users/sphoono/password".path or null;
      };
  };
}

{ den, ... }: {
  imports = [
    ./disko.nix
  ];

  den.hosts.x86_64-linux.laptop-ares.users.sphoono = { };

  den.aspects.laptop-ares.nixos = { pkgs, ... }: {
    hardware.facter.reportPath = ./facter.json;
    boot.plymouth =
      let
        theme = "connect";
      in
      {
        inherit theme;
        themePackages = [
          (pkgs.adi1090x-plymouth-themes.override {
            selected_themes = [
              theme
            ];
          })
        ];
      };
  };

  den.aspects.sphoono = {
    includes = [
      den.batteries.primary-user
      den.aspects.systemd-boot
      den.aspects.zram-swap
    ];
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

{ den, ... }: {
  den.homes.x86_64-linux.sphoono = {
    includes = [
      den.aspects.stylix.standalone
      den.aspects.sphoono.development
      {
        homeManager =
          { config, ... }:
          {
            programs.nh = {
              enable = true;
              clean.enable = true;
              homeFlake = "${config.home.homeDirectory}/Projects/homelab";
            };
          };
      }
    ];
  };
}

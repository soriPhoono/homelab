{ den, ... }: {
  den.aspects.sphoono.desktop = {
    includes = [
      den.aspects.sphoono.gpg
      den.aspects.sphoono.ssh
      den.aspects.sphoono.configs.zen-browser
    ];
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.wl-clipboard ];
      programs.jq.enable = true;
    };
  };
}

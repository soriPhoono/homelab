{ den, ... }: {
  den.aspects.sphoono.core = {
    includes = [
      den.aspects.sphoono.gpg
      den.aspects.sphoono.ssh
      den.aspects.sphoono.core.browser
      den.aspects.sphoono.core.communication
      den.aspects.sphoono.core.office
    ];
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.wl-clipboard ];
      programs.jq.enable = true;
    };
  };
}

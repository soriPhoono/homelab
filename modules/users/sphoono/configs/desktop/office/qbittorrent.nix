{
  den.aspects.sphoono.desktop.office = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        qbittorrent
      ];
    };
  };
}

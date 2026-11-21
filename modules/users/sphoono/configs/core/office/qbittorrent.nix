{
  den.aspects.sphoono.core.office.qbittorrent = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        qbittorrent
      ];
    };
  };
}

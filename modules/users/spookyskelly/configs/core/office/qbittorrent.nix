{
  den.aspects.spookyskelly.core.office.qbittorrent = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        qbittorrent
      ];
    };
  };
}

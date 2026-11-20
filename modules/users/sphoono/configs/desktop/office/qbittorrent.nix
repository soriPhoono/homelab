{
  den.aspects.sphoono.desktop = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        qbittorrent
      ];
    };
  };
}

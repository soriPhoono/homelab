{
  den.aspects.sphoono.development.homeManager =
    { pkgs, ... }:
    {
      # Shell primitives agents reach for when scripting: jq for parsing
      # JSON tool output, wl-clipboard (wl-copy/wl-paste) for handing text
      # to and from the Wayland clipboard.
      programs.jq.enable = true;
      home.packages = [ pkgs.wl-clipboard ];
    };
}

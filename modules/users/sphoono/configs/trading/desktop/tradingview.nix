{ den, ... }:
{
  # A sub-aspect rather than part of sphoono.desktop itself: the base
  # desktop aspect also reaches the standalone home. Hosts opt in.
  den.aspects.sphoono.trading.desktop = {
    # Market charting; the bot services stay in den.aspects.hosting.trading.
    includes = [
      (den.batteries.unfree [ "tradingview" ])
      den.aspects.sphoono.trading
    ];
    homeManager =
      {
        pkgs,
        ...
      }:
      {
        home.packages = [ pkgs.tradingview ];
      };
  };
}

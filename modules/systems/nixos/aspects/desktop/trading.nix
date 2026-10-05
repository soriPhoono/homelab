{ den, ... }:
{
  den.aspects.desktop.domains.trading = {
    desktop = {
      /**
        Market charting on the desktop:
        - TradingView desktop client (HM)
      */

      includes = [
        (den.batteries.unfree [ "tradingview" ])
      ];
      homeManager =
        { pkgs, ... }:
        {
          home.packages = with pkgs; [
            tradingview
          ];
        };
    };
  };
}

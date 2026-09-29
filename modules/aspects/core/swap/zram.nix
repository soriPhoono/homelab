{
  den.aspects.core.swap.zram = _: {
    nixos = _: {
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        priority = 5;
      };
    };
  };
}

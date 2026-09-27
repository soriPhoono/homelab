{
  den.aspects.zram-swap = _: {
    nixos = _: {
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        priority = 5;
      };
    };
  };
}

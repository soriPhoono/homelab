{ den, ... }: {
  den.aspects.sphoono = {
    includes = [
      (den.batteries.user-shell "fish")
    ];
    homeManager.programs.nh.enable = true;
  };
}

{ den, ... }: {
  den.aspects.sphoono = {
    includes = [
      (den.batteries.user-shell "fish")
    ];
  };
}

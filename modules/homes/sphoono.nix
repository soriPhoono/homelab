{ den, ... }: {
  den.homes.x86_64-linux.sphoono = {
    includes = [
      den.aspects.stylix.standalone
    ];
  };
}

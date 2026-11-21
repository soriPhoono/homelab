{ den, ... }: {
  den.aspects.sphoono.core.communication = {
    includes = [
      den.aspects.sphoono.core.discord
      den.aspects.sphoono.core.telegram
    ];
  };
}

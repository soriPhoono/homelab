{ den, ... }: {
  den.aspects.sphoono.core.communication = {
    includes = [
      den.aspects.sphoono.core.communication.discord
      den.aspects.sphoono.core.communication.telegram
    ];
  };
}

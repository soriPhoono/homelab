{ den, ... }: {
  den.aspects.spookyskelly.core.communication = {
    includes = [
      den.aspects.spookyskelly.core.communication.discord
      den.aspects.spookyskelly.core.communication.telegram
    ];
  };
}

{ den, ... }: {
  den.aspects.spookyskelly.core = {
    includes = [
      den.aspects.spookyskelly.core.browser
      den.aspects.spookyskelly.core.communication
      den.aspects.spookyskelly.core.office
    ];

    homeManager = _: {
      programs.jq.enable = true;
    };
  };
}

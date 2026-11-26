{
  den.aspects.spookyskelly.content-creation.audacity.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.audacity ];
    };
}

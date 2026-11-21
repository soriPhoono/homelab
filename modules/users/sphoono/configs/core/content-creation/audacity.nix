{
  den.aspects.sphoono.core.content-creation.audacity.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.audacity ];
    };
}

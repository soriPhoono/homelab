{
  den.aspects.sphoono.content-creation.audacity.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.audacity ];
    };
}

{
  den.aspects.spookyskelly.content-creation.blender.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.blender ];
    };
}

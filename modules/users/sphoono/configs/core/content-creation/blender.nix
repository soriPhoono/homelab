{
  den.aspects.sphoono.core.content-creation.blender.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.blender ];
    };
}

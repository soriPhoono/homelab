{
  den.aspects.sphoono.content-creation.blender.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.blender ];
    };
}

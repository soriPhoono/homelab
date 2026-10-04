{
  den.aspects.sphoono.development.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ (pkgs.callPackage ./_private/openrig/package.nix { }) ];
    };
}

{ den, ... }: {
  den.homes.x86_64-linux.sphoono = {
    includes = [
      den.aspects.stylix.standalone
      den.aspects.sphoono.development
      {
        # Host-attached users get this from den.schema.user in sops.nix.
        homeManager.sops.defaultSopsFile = ../../secrets/user-sphoono.yaml;
      }
    ];
  };
}

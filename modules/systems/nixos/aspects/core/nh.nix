{
  # Home Manager config must ride on den.schema.user: den.schema.host
  # includes only reach the NixOS side, never the host's users.
  den.schema.user.includes = [
    {
      homeManager.programs.nh = {
        enable = true;
        clean.enable = true;
      };
    }
  ];
}

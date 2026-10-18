{
  den.schema = {
    # Give `nh os` a default flake: the admin's checkout where it exists,
    # otherwise the published repo.
    host.includes = [
      (
        { host, ... }:
        {
          nixos.programs.nh = {
            enable = true;
            flake =
              if host.users ? sphoono then "/home/sphoono/Projects/homelab" else "github:soriPhoono/homelab";
          };
        }
      )
    ];
    # Home Manager config must ride on den.schema.user: den.schema.host
    # includes only reach the NixOS side, never the host's users.
    user.includes = [
      {
        homeManager.programs.nh = {
          enable = true;
          clean.enable = true;
        };
      }
    ];
  };
}

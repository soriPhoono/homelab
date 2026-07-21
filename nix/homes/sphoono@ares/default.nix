{
  imports = [
    ./hypr.nix
    ./apps.nix
    ./configs
  ];

  core = {
    shells = {
      shellAliases = {
        lzg = "lazygit";

        d = "docker";
        dc = "docker compose";
      };
    };
  };
}

{
  imports = [
    ./hypr.nix
    ./apps.nix
  ];

  core = {
    shells.shellAliases = {
      lzg = "lazygit";

      d = "docker";
      dc = "docker compose";
    };
  };
}

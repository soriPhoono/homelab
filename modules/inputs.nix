{
  flake-file.inputs = {
    home-manager.url = "github:nix-community/home-manager";
    darwin.url = "github:nix-darwin/nix-darwin";
    disko.url = "github:nix-community/disko";
    templates.url = "github:soriphoono/templates";
    # Fork of noctalia-dev/community-plugins carrying the work-clock plugin,
    # a pomodoro timer derived from thepunkoff/pomodoro (not merged upstream).
    work-clock-plugin = {
      url = "github:soriPhoono/community-plugins?ref=feat/work-clock";
      flake = false;
    };
    herdr-nvim = {
      url = "github:ChmaraX/herdr-nvim/v1.1.0";
      flake = false;
    };
  };
}

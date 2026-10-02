{
  flake-file.inputs = {
    home-manager.url = "github:nix-community/home-manager";
    darwin.url = "github:nix-darwin/nix-darwin";
    disko.url = "github:nix-community/disko";
    templates.url = "github:soriphoono/templates";
    herdr-nvim = {
      url = "github:ChmaraX/herdr-nvim/v1.1.0";
      flake = false;
    };
  };
}

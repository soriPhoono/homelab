{pkgs, ...}: {
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  # Example package
  home.packages = with pkgs; [
    hello
  ];
}

{pkgs, ...}: {
  system.stateVersion = "24.05";

  # Simple default configuration
  environment.packages = with pkgs; [
    vim
    git
  ];
}

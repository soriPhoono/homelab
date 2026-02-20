{pkgs, ...}: {
  system.stateVersion = "24.05";

  core.users.soriphoono = {};

  # Simple default configuration
  environment.packages = with pkgs; [
    vim
    git
  ];
}

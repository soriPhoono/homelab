{pkgs, ...}: {
  system.stateVersion = "24.05";

  core.user.shell = pkgs.fish;

  android-integration = {
    am.enable = true;
    termux-open-url.enable = true;
    termux-reload-settings.enable = true;
    termux-setup-storage.enable = true;
    xdg-open.enable = true;
  };
}

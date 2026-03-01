{pkgs, lib, ...}: {
  system.stateVersion = "24.05";

  core.user.shell = pkgs.fish;

  user.userName = lib.mkForce "nix-on-droid";

  android-integration = {
    am.enable = true;
    termux-open-url.enable = true;
    termux-reload-settings.enable = true;
    termux-setup-storage.enable = true;
    xdg-open.enable = true;
  };
}

{lib, ...}:
with lib; {
  imports = [
    ./desktop
    ./development
    ./data-fortress
    ./content-creation
  ];

  options.userapps.defaultApplications.enable = mkEnableOption "Set default applications (xdg.mimeApps) via Nix";
}

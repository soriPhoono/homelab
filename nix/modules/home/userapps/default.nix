{lib, ...}:
with lib; {
  imports = [
    ./development
    ./file-browsers
    ./browsers
    ./data-fortress
    ./office
    ./communication
    ./content-creation
  ];

  options.userapps.defaultApplications.enable = mkEnableOption "Set default applications (xdg.mimeApps) via Nix";
}

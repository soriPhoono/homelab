{lib, ...}:
with lib; {
  imports = [
    ./browsers
    ./communication
    ./content-creation
    ./data-fortress
    ./development
    ./file-browsers
    ./office
  ];

  options.userapps.defaultApplications.enable = mkEnableOption "Set default applications (xdg.mimeApps) via Nix";
}

{lib, ...}:
with lib; {
  imports = [
    ./browsers
    ./communication
    ./development
    ./data-fortress
    ./office
  ];

  options.userapps.defaultApplications.enable = mkEnableOption "Set default applications (xdg.mimeApps) via Nix";
}

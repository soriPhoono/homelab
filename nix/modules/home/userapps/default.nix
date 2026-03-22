{lib, ...}:
with lib; {
  imports = [
    ./browsers
    ./communication
    ./development
    ./data-fortress
    ./office
  ];

  options.userapps = {
    enable = mkEnableOption "Enable core applications and default feature-set";
    defaultApplications.enable = mkEnableOption "Set default applications (xdg.mimeApps) via Nix";
  };
}

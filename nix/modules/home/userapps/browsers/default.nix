{lib, ...}: {
  imports = [
    ./librewolf.nix
    ./firefox.nix
    ./chrome.nix
    ./floorp.nix
  ];

  options.userapps.defaultApplications.enable = lib.mkEnableOption "Set default applications (xdg.mimeApps) via Nix";
}

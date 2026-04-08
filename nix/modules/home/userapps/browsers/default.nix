{
  lib,
  config,
  ...
}: {
  imports = [
    ./zen.nix
    ./firefox.nix
    ./chrome.nix
    ./floorp.nix
  ];

  options.userapps.browsers.enable = lib.mkEnableOption "Enable browser component configuration";

  config = lib.mkIf config.userapps.browsers.enable {
    services.psd = {
      enable = true;
      resyncTimer = "10m";
    };
  };
}

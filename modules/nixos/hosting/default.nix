{lib, ...}:
with lib; {
  imports = [
    ./blocks
  ];

  options.hosting = {
    enable = mkEnableOption "Enable hosting features";
  };
}

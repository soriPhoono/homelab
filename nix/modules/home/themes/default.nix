{lib, ...}:
with lib; {
  imports = [
    ./qt.nix
  ];

  options.themes = {
    enable = mkEnableOption "Enable home manager theming";
  };
}

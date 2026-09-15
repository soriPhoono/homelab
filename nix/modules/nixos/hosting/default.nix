{lib, ...}:
with lib; {
  imports = [
    ./platforms
    ./proxy
    ./gaming
    ./media
  ];
}

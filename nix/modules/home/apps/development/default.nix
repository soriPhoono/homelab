{lib, ...}:
with lib; {
  imports = [
    ./agents
    ./appliances
    ./design
    ./editors
    ./inference
    ./infrastructure
    ./terminal
  ];
}

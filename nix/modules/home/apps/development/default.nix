{
  imports = [
    ./agents
    ./appliances
    ./design
    ./editors
    ./inference
    ./infrastructure
    ./terminal
  ];

  config = {
    programs = {
      uv.enable = true;
      npm.enable = true;
    };
  };
}

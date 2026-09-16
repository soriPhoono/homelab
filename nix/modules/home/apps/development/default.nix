{
  imports = [
    ./agents
    ./appliances
    ./design
    ./editors
    ./terminal
  ];

  config = {
    programs = {
      uv.enable = true;
      npm.enable = true;
    };
  };
}

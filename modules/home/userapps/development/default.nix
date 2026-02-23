{
  imports = [
    ./agents
    ./editors
    ./terminal
  ];

  config = {
    programs = {
      npm.enable = true;
    };
  };
}

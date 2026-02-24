{
  imports = [
    ./agents
    ./editors
    ./terminal
    ./knowledge-management
  ];

  config = {
    programs = {
      npm.enable = true;
    };
  };
}

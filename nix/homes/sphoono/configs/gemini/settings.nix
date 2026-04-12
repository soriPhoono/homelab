{
  programs.gemini-cli.settings = {
    ide = {
      enabled = true;
    };
    privacy = {
      usageStatisticsEnabled = false;
    };
    security = {
      auth = {
        selectedType = "oauth-personal";
      };
    };
    tools = {
      autoAccept = false;
    };
  };
}

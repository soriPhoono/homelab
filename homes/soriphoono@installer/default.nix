{
  core = {
    shells.fish.generateCompletions = true;
  };

  userapps = {
    enable = true;
    browsers = {
      chrome.enable = true;
      librewolf.enable = true;
    };
    communication = {
      discord.enable = true;
    };
    data-fortress = {
      nextcloud.enable = true;
      bitwarden.enable = true;
    };
    office = {
      onlyoffice.enable = true;
    };
    development = {
      enable = true;
      terminal = {
        ghostty.enable = true;
      };
      knowledge-management.obsidian.enable = true;
      editors.antigravity.enable = true;
      domain_specific.k8s.enable = true;
    };
  };
}

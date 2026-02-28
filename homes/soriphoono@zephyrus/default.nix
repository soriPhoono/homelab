{config, ...}: {
  core = {
    shells.fish.generateCompletions = true;

    git = {
      projectsDir = "${config.home.homeDirectory}/Documents/Projects/";
      extraIdentities = {
        school = {
          directory = "School";
          name = "soriphoono";
          email = "soriphoono@gmail.com";
          signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPcVuhOU+afO33xi1Jb0VHZXlDwXMl0smJnxzSwZpysG soriphoono@zephyrus";
        };
        work = {
          directory = "Work";
          name = "xrezdev11";
          email = "xrezdev11@gmail.com";
          signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPAxax8ouXfptDoQkw4C0FgA4USyS8U6UZu76RRE2VtI";
        };
      };
    };
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
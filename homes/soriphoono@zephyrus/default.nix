{config, ...}: {
  imports = [
    ./nvim
  ];

  core = {
    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yaml;
    };

    shells.shellAliases.v = "nvim";

    git = {
      userName = "soriphoono";
      userEmail = "soriphoono@gmail.com";
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
      librewolf.enable = true;
      chrome.enable = true;
    };
    development = {
      terminal = {
        ghostty.enable = true;
      };
      editors = {
        vscode.enable = true;
      };
    };
    agents = {
      gemini = {
        enable = true;
        overrideEditor = true;
      };
    };
  };
}

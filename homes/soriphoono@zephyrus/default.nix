{
  config,
  pkgs,
  ...
}: {
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
      agents = {
        gemini = {
          enable = true;
          overrideEditor = true;
        };
        claude.enable = true;

        mcp-servers = {
          github = {
            command = "${pkgs.mcp-server-github}/bin/github-mcp-server";
            args = ["stdio"];
            env.GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
          };
          git.command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
          fetch.command = "${pkgs.mcp-server-fetch}/bin/mcp-server-fetch";
          filesystem = {
            command = "${pkgs.mcp-server-filesystem}/bin/mcp-server-filesystem";
            args = ["/home/soriphoono"];
          };
          memory.command = "${pkgs.mcp-server-memory}/bin/mcp-server-memory";
          sequential-thinking.command = "${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking";
          mermaid.command = "${pkgs.mcp-server-mermaid}/bin/mermaid-mcp-server";
        };
      };
    };
  };
}

{config, ...}: {
  imports = [
    ./nvim
  ];

  sops.secrets."github/api-key" = {};

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
      chrome.enable = true;
    };
    development = {
      editors = {
        vscode.enable = true;
      };
      agents = {
        gemini = {
          enable = true;
          overrideEditor = true;
        };
        claude.enable = true;
      };
    };
  };

  programs.gemini-cli = {
    enable = true;

    mcps = let
      inherit (config.home) homeDirectory;
      projectsDirectory = "${homeDirectory}/Documents/Projects";
    in {
      github = {
        enable = true;
        baseURL = null; # not using GitHub Enterprise
        tokenFilepath = config.sops.secrets."github/api-key".path;
      };

      # Enabled Servers without secrets
      git.enable = true;
      filesystem = {
        enable = true;
        allowedPaths = [homeDirectory];
      };
      sequential-thinking.enable = true;
      time = {
        enable = true;
        localTimezone = "America/Chicago"; # Updated to match user's apparent timezone (based on earlier metadata or safe default)
      };
      nixos.enable = true;
      fetch = {
        enable = true;
        ignoreRobotsTxt = false;
      };
      ast-grep.enable = true;

      # Language Servers (LSPs)
      lsp-nix = {
        enable = true;
        workspace = projectsDirectory;
      };
      lsp-python = {
        enable = true;
        workspace = projectsDirectory;
      };
      lsp-typescript = {
        enable = true;
        workspace = projectsDirectory;
      };
      lsp-golang = {
        enable = true;
        workspace = projectsDirectory;
      };
      lsp-rust = {
        enable = true;
        workspace = projectsDirectory;
      };

      # Servers requiring secrets (Configured with placeholders/instructions)
      /*
      asana = {
        enable = true;
        tokenFilepath = config.sops.secrets."asana/api-key".path;
      };
      buildkite = {
        enable = true;
        apiKeyFilepath = config.sops.secrets."buildkite/api-key".path;
      };
      grafana = {
        enable = true;
        baseURL = "http://localhost:3000"; # Modify as needed
        apiKeyFilepath = config.sops.secrets."grafana/api-key".path;
      };
      obsidian = {
        enable = true;
        host = "127.0.0.1";
        port = 27124;
        apiKeyFilepath = config.sops.secrets."obsidian/api-key".path;
      };
      */
    };
  };
}

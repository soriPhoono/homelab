{pkgs, ...}: let
  # ACP Client extension — not in nixpkgs, fetched from marketplace
  acpClient = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "formulahendry";
      name = "acp-client";
      version = "0.2.0";
      sha256 = "sha256-rvjqvp0xHgfIo06qqMKpZd240GoA8J1lH6tUVX3lUTk=";
    };
  };
in {
  userapps.development.editors.vscode = {
    # Common extensions added to every profile
    common.extensions = with pkgs.vscode-extensions; [
      catppuccin.catppuccin-vsc
      github.copilot
      github.copilot-chat

      # ACP Client — AI agent protocol integration
      acpClient
    ];

    # Named extension profiles
    extensionProfiles = {
      # Default profile — general-purpose extensions
      default.extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        jnoortheen.nix-ide
        mkhl.direnv
        golang.go
        rust-lang.rust-analyzer
        tamasfe.even-better-toml
        ms-python.python
        ms-python.vscode-pylance
        esbenp.prettier-vscode
        foxundermoon.shell-format
        timonwong.shellcheck
        redhat.vscode-yaml
        yzhang.markdown-all-in-one
        streetsidesoftware.code-spell-checker
        eamodio.gitlens
        mhutchie.git-graph
        vscodevim.vim
      ];

      # Nix-specific profile — focused on Nix development
      nix.extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        jnoortheen.nix-ide
        mkhl.direnv
      ];
    };
  };
}

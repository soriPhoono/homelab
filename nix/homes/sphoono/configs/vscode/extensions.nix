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
  userapps.development.editors.code-oss = {
    # Common extensions added to every profile
    common.extensions = with pkgs.vscode-extensions; [
      catppuccin.catppuccin-vsc

      # ACP Client — AI agent protocol integration
      acpClient
    ];

    # Named extension profiles
    extensionProfiles = {
      # Default profile — general-purpose extensions
      default.extensions = with pkgs.vscode-extensions; [
        mkhl.direnv
        jnoortheen.nix-ide

        foxundermoon.shell-format
        timonwong.shellcheck

        golang.go

        tamasfe.even-better-toml
        rust-lang.rust-analyzer

        ms-python.python
        ms-python.vscode-pylance

        esbenp.prettier-vscode

        streetsidesoftware.code-spell-checker
        yzhang.markdown-all-in-one

        redhat.vscode-yaml
      ];
    };
  };
}

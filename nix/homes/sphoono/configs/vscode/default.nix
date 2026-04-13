{
  pkgs,
  lib,
  ...
}: {
  userapps.development.editors.vscode = {
    package = pkgs.symlinkJoin {
      pname = pkgs.antigravity.pname or "vscode";
      version = pkgs.antigravity.version or "latest";
      name = "${pkgs.antigravity.name or "antigravity"}-wrapped";

      paths = [pkgs.antigravity];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/antigravity \
          --prefix PATH : ${lib.makeBinPath [pkgs.google-chrome]}
      '';

      meta.mainProgram = pkgs.antigravity.meta.mainProgram or "antigravity";
    };

    extensions = with pkgs.vscode-marketplace;
    with pkgs.vscode-marketplace-universal; [
      # Desktop / System
      mkhl.direnv
      jnoortheen.nix-ide

      # Git / Extra
      eamodio.gitlens

      # Agentic AI
      google.geminicodeassist
      googlecloudtools.cloudcode
      google.gemini-cli-vscode-ide-companion

      # Security
      snyk-security.snyk-vulnerability-scanner
      sonarsource.sonarlint-vscode

      # Languages
      redhat.vscode-yaml
      redhat.vscode-xml
      tamasfe.even-better-toml
      mads-hartmann.bash-ide-vscode
      sumneko.lua
      ms-python.python
      ms-toolsai.jupyter
      vadimcn.vscode-lldb
      llvm-vs-code-extensions.vscode-clangd
      ziglang.vscode-zig
      rust-lang.rust-analyzer
      golang.go
      redhat.java
      vscjava.vscode-java-debug
      vscjava.vscode-java-test
      vscjava.vscode-gradle
      ms-dotnettools.csharp

      # DevOps
      google.colab
      hashicorp.terraform
      redhat.ansible
      ms-azuretools.vscode-containers
      ms-kubernetes-tools.vscode-kubernetes-tools
      tim-koehler.helm-intellisense

      # Web2 Development
      denoland.vscode-deno
      bradlc.vscode-tailwindcss
      astro-build.astro-vscode
      vue.volar
      svelte.svelte-vscode

      # Web3 / Crypto
      nomicfoundation.hardhat-solidity
    ];

    userSettings = {
      "git.confirmSync" = false;

      "snyk.advanced.cliPath" = "/home/sphoono/.local/share/snyk/vscode-cli/snyk-linux";

      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
        "editor.formatOnSave" = true;
      };
    };
  };
}

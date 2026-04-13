{pkgs, ...}: {
  userapps.development.editors.vscode = {
    extensions = with pkgs.vscode-marketplace-universal; [
      # Desktop / System
      mkhl.direnv
      jnoortheen.nix-ide

      # Git / Extra
      eamodio.gitlens

      # Agentic AI
      google.gemini-cli-vscode-ide-companion

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
  };
}

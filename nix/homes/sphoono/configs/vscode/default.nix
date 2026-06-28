{pkgs, ...}: {
  imports = [
    ./settings.nix
    ./extensions.nix
    ./keybindings.nix
    ./snippets.nix
  ];

  userapps.development.editors.code-oss = {
    # Active profiles — switch via VS Code profile picker
    activeProfiles = ["devops" "fullstack" "webdev"];

    # Extra packages (LSP servers, formatters, linters)
    extraPackages = with pkgs; [
      nixd
      nil
      rust-analyzer
      opentofu
    ];
  };
}

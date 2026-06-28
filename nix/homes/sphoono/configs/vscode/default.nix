{pkgs, ...}: {
  imports = [
    ./settings.nix
    ./extensions.nix
  ];

  userapps.development.editors.vscode = {
    enable = true;

    # Active profiles to use
    activeProfiles = ["default" "nix"];

    # Extra packages (LSP servers, formatters, linters)
    extraPackages = with pkgs; [
      nixd
      nil
    ];
  };
}

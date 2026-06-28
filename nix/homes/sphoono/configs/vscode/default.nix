{pkgs, ...}: {
  imports = [
    ./settings.nix
    ./extensions.nix
  ];

  userapps.development.editors.code-oss = {
    # Active profiles to use
    activeProfiles = ["default"];

    # Extra packages (LSP servers, formatters, linters)
    extraPackages = with pkgs; [
      nixd
      nil
    ];
  };
}

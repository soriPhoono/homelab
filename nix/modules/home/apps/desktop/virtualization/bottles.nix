{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.desktop.virtualization.bottles;

  # Override bottles to bundle Mesa GPU drivers into the FHS environment.
  # Without this, Wine's OpenGL/Vulkan stack cannot find the actual GPU
  # driver implementations — only the GLVND dispatcher and Vulkan loader
  # are present, and they fail with "graphics driver is missing".
  #
  # pkgs.mesa is the NixOS-provided set of Mesa drivers (symlinked
  # from /run/opengl-driver on the host). It includes DRI, Vulkan, and VAAPI
  # drivers for all GPU families (Intel, AMD, NVIDIA via Nouveau), making
  # this fix architecture-neutral and system-independent.
  bottles' = pkgs.bottles.override {
    extraLibraries = p: [p.mesa];
  };
in
  with lib; {
    options.apps.desktop.virtualization.bottles = {
      enable = mkEnableOption "Enable bottles for running Windows applications via WINE";
    };

    config = mkIf cfg.enable {
      home.packages = [
        bottles'
      ];
    };
  }

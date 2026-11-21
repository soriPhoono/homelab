{ inputs, ... }: {
  flake-file.inputs.nix-skills.url = "github:sudosubin/nix-skills";

  den.aspects.sphoono.development.opencode = {
    homeManager = {
      imports = [
        ./_private
      ];

      nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];
    };
  };

  # OpenCode Desktop, for hosts with a desktop. It reads the same
  # ~/.config/opencode as the CLI, so it shares the settings, providers, MCP
  # servers, skills and plugin above.
  den.aspects.sphoono.development.opencode.desktop.homeManager =
    { lib, pkgs, ... }:
    let
      desktop = import ./_private/wrap-opencode.nix { inherit lib pkgs; } pkgs.opencode-desktop;
      inherit (import ../../desktop/wm/hypr/_private/lib.nix { inherit lib; }) bind exec;
    in
    {
      home.packages = [ desktop ];

      # Declared here rather than with the global binds, so the key exists
      # only where the app does. Inert on a home without Hyprland.
      wayland.windowManager.hyprland.settings.bind = [
        (bind "SUPER + C" (exec "${lib.getExe pkgs.uwsm} app -- ${lib.getExe desktop}"))
      ];
    };
}

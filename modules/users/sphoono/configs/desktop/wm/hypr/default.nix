{ den, lib, ... }: {
  den.aspects.sphoono.desktop.wm.hypr = {
    includes = [
      den.aspects.sphoono.desktop.wm.supporting
    ];
    homeManager =
      {
        nixosConfig ? { },
        ...
      }:
      let
        hostHyprland = nixosConfig.programs.hyprland or { enable = false; };
      in
      {
        imports = [
          ./_private
        ];

        wayland.windowManager.hyprland = {
          enable = true;
          configType = "lua";

          # Reuse the NixOS module's packages rather than nulling them: a null
          # portal package disables the user portal set, which then lacks xdph.
          package = lib.mkIf hostHyprland.enable hostHyprland.package;
          portalPackage = lib.mkIf hostHyprland.enable hostHyprland.portalPackage;

          # UWSM owns the session: it exports the environment and starts
          # graphical-session.target, so HM's hyprland-session.target would
          # only restart it underneath uwsm.
          systemd.enable = false;
        };
      };
  };
}

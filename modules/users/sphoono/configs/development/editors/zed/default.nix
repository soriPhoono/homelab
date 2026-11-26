{
  den.aspects.sphoono.development.editors.zed = {
    homeManager = { lib, pkgs, ... }: {
      imports = [
        ./_private
      ];

      programs.zed-editor = {
        enable = true;
        mutableUserDebug = false;
        mutableUserKeymaps = false;
        mutableUserSettings = false;
        mutableUserTasks = false;
      };

      wayland.windowManager.hyprland.settings.bind =
        let
          package = pkgs.zed-editor;
          inherit (import ../../../core/wm/hypr/_private/lib.nix { inherit lib; }) bind exec;
        in
        [
          (bind "SUPER + C" (exec "${lib.getExe pkgs.uwsm} app -- ${lib.getExe package}"))
        ];
    };
  };
}

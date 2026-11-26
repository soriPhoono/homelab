{ inputs, ... }: {
  flake-file.inputs.nix-skills.url = "github:sudosubin/nix-skills";

  # Inputs the opencode aspect consumes. nix-skills has not yet indexed
  # awesome-copilot and mattpocock-skills (tracked in its sources.json but no
  # skill data generated), so those two are taken directly instead of through
  # pkgs.agent-skills.
  flake-file.inputs = {
    awesome-ai-agent-skills = {
      url = "github:seb1n/awesome-ai-agent-skills/75865a5d037a4cdaa7f409a4ec14ab9b0292920b";
      flake = false;
    };
    awesome-copilot = {
      url = "github:github/awesome-copilot/d6131471b85fbb4799e64175ebc42c9309ecc28a";
      flake = false;
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills/d81f3a183412e71a5b1e84ca21bc1a35eea03a60";
      flake = false;
    };
  };

  den.aspects.sphoono.development.agents.opencode = {
    homeManager =
      { lib, pkgs, ... }:
      {
        imports = [
          (import ./_private { inherit inputs lib pkgs; })
        ];

        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];
      };
  };

  # OpenCode Desktop, for hosts with a desktop. It reads the same
  # ~/.config/opencode as the CLI, so it shares the settings, providers, MCP
  # servers, skills and plugin above.
  den.aspects.sphoono.development.agents.opencode.desktop.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      desktop = pkgs.opencode-desktop;
    in
    {
      home.packages = [ desktop ];

      # Hermes Desktop binds the same Copilot key. `or false` covers homes
      # that do not import the hermes-agent module at all.
      assertions = [
        {
          assertion = !(config.programs.hermes-agent.desktop.enable or false);
          message = "sphoono.development.agents.opencode.desktop and sphoono.development.agents.hermes.desktop both bind the Copilot key (SUPER + SHIFT + code:201); include only one of them.";
        }
      ];

      wayland.windowManager.hyprland.settings.bind =
        let
          inherit (import ../../../core/wm/hypr/_private/lib.nix { inherit lib; }) bind exec;
        in
        [
          # The Copilot key sends Super_L + Shift_L + F23. F23 is xkb keycode
          # 201, which the default keymap maps to XF86TouchpadOff, so match
          # the raw keycode rather than a keysym.
          (bind "SUPER + SHIFT + code:201" (exec "${lib.getExe pkgs.uwsm} app -- ${lib.getExe desktop}"))
        ];
    };
}

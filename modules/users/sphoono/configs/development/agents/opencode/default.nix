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
    { lib, pkgs, ... }:
    let
      desktop = pkgs.opencode-desktop;
      inherit (import ../../../core/wm/hypr/_private/lib.nix { inherit lib; }) bind exec;
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

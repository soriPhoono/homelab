{ den, inputs, ... }: {
  flake-file.inputs.nix-openclaw.url = "github:openclaw/nix-openclaw";

  den.aspects.sphoono.development.agents.openclaw = {
    includes = [
      (den.batteries.insecure [ "openclaw-2026.10.5" ])
    ];

    homeManager = {
      imports = [
        inputs.nix-openclaw.homeManagerModules.openclaw
      ];

      nixpkgs.overlays = [
        inputs.nix-openclaw.overlays.default
      ];

      programs.openclaw = {
        enable = true;

        workspace.bootstrapFiles = {
          agents = ./assets/AGENTS.md;
          soul = ./assets/agents/default.md;
          tools = ./assets/TOOLS.md;
          identity = ./assets/IDENTITY.md;
          user = ../assets/USER.md;
        };

        config = {
          gateway = {
            mode = "local";
          };
        };
      };
    };
  };
}

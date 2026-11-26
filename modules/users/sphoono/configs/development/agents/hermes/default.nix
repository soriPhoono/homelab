{
  den,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.hermes-agent.url = "github:soriPhoono/hermes-agent";

  den.aspects.sphoono.development.agents.hermes = {
    homeManager =
      { config, ... }:
      {
        imports = [
          inputs.hermes-agent.homeManagerModules.default
        ];

        programs.hermes-agent.enable = true;

        # Hermes is the top-level assistant and delegates project work to
        # OpenCode. With the gateway off and no backend this starts no
        # daemon: it only runs the activation that merges config.yaml and
        # installs the files below.
        services.hermes-agent = {
          enable = true;

          # The host has the rootful docker CLI on PATH as well, and Hermes
          # prefers docker over podman. Force rootless Podman: root in the
          # sandbox is then this user on the host, not root.
          environment.HERMES_DOCKER_BINARY = "podman";

          # Every shell, file and code tool call runs in a sandbox container.
          # Each session gets a fresh one, removed when the session closes,
          # with only the session's attached project mounted at /workspace.
          # The OpenCode runs Hermes delegates to start in that container.
          settings.terminal = {
            backend = "docker";
            docker_image = "docker.io/nousresearch/hermes-sandbox:desktop";
            container_persistent = false;
            docker_mount_cwd_to_workspace = true;

            # Long OpenCode runs go quiet between polls; the 300 s default
            # reaps the container under them.
            lifetime_seconds = 1800;
            container_cpu = 4;
            container_memory = 8192;

            docker_volumes =
              let
                home = config.home.homeDirectory;
              in
              [
                # The wrapped OpenCode and its Home Manager config are store
                # paths and symlinks into the store.
                "/nix/store:/nix/store:ro"
                "${lib.getExe config.programs.opencode.package}:/usr/local/bin/opencode:ro"
                "${home}/.config/opencode:/root/.config/opencode:ro"
                # The OAuth credentials. Writable, because OpenCode writes the
                # refreshed token back.
                "${home}/.local/share/opencode/auth.json:/root/.local/share/opencode/auth.json"
              ];
          };

          hermesHomeFiles = {
            "SOUL.md" = ./assets/SOUL.md;

            # The official optional skill, from the pinned input rather than
            # the hub, so it follows flake updates.
            "skills/autonomous-ai-agents/opencode/SKILL.md" =
              builtins.readFile "${inputs.hermes-agent}/optional-skills/autonomous-ai-agents/opencode/SKILL.md";
          };
        };

        assertions = [
          {
            assertion = config.programs.opencode.enable or false;
            message = "sphoono.development.agents.hermes delegates coding to OpenCode; include sphoono.development.agents.opencode in the same home.";
          }
        ];
      };

    hosting = {
      homeManager = {

      };
    };

    desktop = {
      includes = [
        den.aspects.sphoono.development.agents.hermes
      ];

      homeManager = { config, pkgs, ... }: {
        programs.hermes-agent.desktop.enable = true;

        # OpenCode Desktop binds the same Copilot key.
        assertions = [
          {
            assertion = !(lib.elem pkgs.opencode-desktop config.home.packages);
            message = "sphoono.development.agents.hermes.desktop and sphoono.development.agents.opencode.desktop both bind the Copilot key (SUPER + SHIFT + code:201); include only one of them.";
          }
        ];

        wayland.windowManager.hyprland.settings.bind =
          let
            package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
            inherit (import ../../../core/wm/hypr/_private/lib.nix { inherit lib; }) bind exec;
          in
          [
            (bind "SUPER + SHIFT + code:201" (exec "${lib.getExe pkgs.uwsm} app -- ${lib.getExe package}"))
          ];
      };
    };
  };
}

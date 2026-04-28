{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.opencode;
  agentContext = config.userapps.development.agents.context;
  combinedContext = let
    parts =
      (lib.optional (agentContext.system != null) agentContext.system)
      ++ (lib.optional (agentContext.user != null) agentContext.user);
  in
    if parts == []
    then null
    else lib.concatStringsSep "\n\n" parts;
in
  with lib; {
    options.userapps.development.agents.opencode = {
      enable = mkEnableOption "Enable OpenCode AI agent";
      enableDesktop = mkEnableOption "Enable OpenCode desktop application (requires opencode-desktop package)";

      secrets = mkOption {
        type = with types; listOf str;
        description = "Secret names to load in from sops for opencode functionality";
        default = [];
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.packages = with pkgs;
          mkIf cfg.enableDesktop [
            opencode-desktop
          ];

        programs.opencode.enable = true;

        home.file.".config/opencode/AGENTS.md" = mkIf (combinedContext != null) {
          text = combinedContext;
        };
      }
      (mkIf (options ? sops && cfg.secrets != []) {
        sops.secrets = genAttrs cfg.secrets (_: {});

        programs.opencode.package = pkgs.symlinkJoin {
          name = "opencode-wrapped";
          paths = [pkgs.opencode];
          buildInputs = [pkgs.makeWrapper];

          postBuild = ''
            for bin in $out/bin/*; do
              # Ensure it is actually a file and is executable before wrapping
              if [ -f "$bin" ] && [ -x "$bin" ]; then
                # Pass ALL --run commands into a SINGLE wrapProgram invocation
                wrapProgram "$bin" \
                  ${concatStringsSep " \\\n                  " (
              map
              (secret: "--run '[ -f ${config.sops.secrets.${secret}.path} ] && export ${baseNameOf secret}=\"$(cat ${config.sops.secrets.${secret}.path})\"'")
              cfg.secrets
            )}
              fi
            done
          '';
        };
      })
    ]);
  }

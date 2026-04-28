{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.gemini;
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
    options.userapps.development.agents.gemini = {
      enable = mkEnableOption "Gemini agent for development";

      secrets = mkOption {
        type = with types; listOf str;
        description = "Secret names to load in from sops for Gemini agent functionality";
        default = [];
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        programs.gemini-cli.enable = true;

        home.file.".gemini/GEMINI.md" = mkIf (combinedContext != null) {
          text = combinedContext;
        };
      }
      (mkIf (options ? sops && cfg.secrets != []) {
        sops.secrets = genAttrs cfg.secrets (_: {});

        programs.gemini-cli.package = pkgs.symlinkJoin {
          name = "gemini-wrapped";
          paths = [pkgs.gemini-cli];
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

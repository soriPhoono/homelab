{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.cursor;
  agentContext = config.userapps.development.agents.context;
  combinedContext = let
    parts =
      (lib.optional (agentContext.system != null) agentContext.system)
      ++ (lib.optional (agentContext.user != null) agentContext.user);
  in
    if parts == []
    then null
    else lib.concatStringsSep "\n\n" parts;

  ruleBody =
    if combinedContext == null
    then ""
    else ''
      ${combinedContext}

      ---
      *Derived from `userapps.development.agents.context` (Data Fortress homelab).*
    '';
in
  with lib; {
    options.userapps.development.agents.cursor = {
      enable = mkEnableOption ''
        Cursor Agent context files under ~/.cursor (rules + AGENTS.md), optional secret wrapping for Cursor CLI,
        and coordination with the VS Code/Cursor editor module for installing `cursor-cli`.
      '';

      secrets = mkOption {
        type = with types; listOf str;
        description = "Secret names to load from sops for Cursor Agent CLI (same pattern as Gemini/OpenCode).";
        default = [];
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home = {
          file.".cursor/AGENTS.md" = mkIf (combinedContext != null) {
            text = ''
              # Agent context

              ${ruleBody}
            '';
          };
          packages = with pkgs; [cursor-cli];
        };
      }
      (mkIf (options ? sops && cfg.secrets != []) {
        sops.secrets = genAttrs cfg.secrets (_: {});

        home.packages = with pkgs; [
          (symlinkJoin {
            name = "cursor-cli-wrapped";
            paths = [cursor-cli];
            buildInputs = [makeWrapper];

            postBuild = ''
              for bin in $out/bin/*; do
                if [ -f "$bin" ] && [ -x "$bin" ]; then
                  wrapProgram "$bin" \
                    ${concatStringsSep " \\\n                      " (
                map
                (secret: "--run '[ -f ${config.sops.secrets.${secret}.path} ] && export ${baseNameOf secret}=\"$(cat ${config.sops.secrets.${secret}.path})\"'")
                cfg.secrets
              )}
                fi
              done
            '';
          })
        ];
      })
    ]);
  }

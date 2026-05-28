/**
Zed editor module
- Requires dynamically enabling github desktop (DONE)
- Requires setting mime associations for text (DONE)
- Configure settings for editor (e.g. font, theme) (DONE)
- Install editor extensions (DONE)
- Configure stylix for editor (optional) (DONE)
- Requires setting editor rules for editor agent context
- Requires dynamically generating zed mcp config (DONE)
*/
{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  editorCfg = config.userapps.development.agentics.editors;
  cfg = config.userapps.development.editors.zed;

  # Auto-discover MCP server secrets from the editor MCP config and merge
  # with the user-declared harness secrets, so both flow into the wrapper.
  mcpSecrets = let
    extractSecretNames = attrs:
      lib.filter (v: v != null) (
        lib.mapAttrsToList (
          _: val:
            if builtins.isAttrs val && val ? "secret"
            then val.secret
            else null
        )
        attrs
      );
  in
    lib.flatten (lib.mapAttrsToList (
        _: srv:
          extractSecretNames (srv.env or {} // srv.headers or {})
      )
      editorCfg.mcp);

  allSecrets = lib.unique (cfg.secrets ++ mcpSecrets);

  codeMimeTypes = [
    "inode/x-empty"
    "text/plain"
    "text/markdown"
    "text/x-markdown"
    "text/javascript"
    "text/css"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/x-cmake"
    "text/x-diff"
    "text/x-go"
    "text/x-java"
    "text/x-kotlin"
    "text/x-lua"
    "text/x-makefile"
    "text/x-nix"
    "text/x-python"
    "text/x-ruby"
    "text/x-rust"
    "text/x-script.python"
    "text/x-shellscript"
    "text/x-sql"
    "text/x-toml"
    "text/x-typescript"
    "text/x-typescript-jsx"
    "text/x-yaml"
    "application/json"
    "application/ld+json"
    "application/javascript"
    "application/toml"
    "application/xml"
    "application/x-shellscript"
    "application/x-yaml"
  ];
in
  with lib; {
    options.userapps.development.editors.zed = {
      enable = mkEnableOption "Enable zed text editor";

      priority = mkOption {
        type = types.int;
        description = "The priority of the zed editor";
        default = 20; # Clean this up by referencing basic common priorities from a global import
      };

      secrets = mkOption {
        type = with types; listOf str;
        description = "List of secrets to inject into zed.";
        default = [];
      };

      extensions = mkOption {
        type = with types; listOf str;
        default = [];
        description = "List of Zed extensions to install.";
      };

      userSettings = mkOption {
        type = with types; attrs;
        default = {};
        description = "User settings for Zed.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (
          let
            editor = ["${baseNameOf (lib.getExe config.programs.zed-editor.package)}.desktop"];
          in
            mkOverride cfg.priority (
              builtins.listToAttrs (map (mime: lib.nameValuePair mime editor) codeMimeTypes)
            )
        );

        userapps.development = {
          infrastructure.github = {
            enable = true;
            enableDesktop = true;
          };
          agents.opencode = {
            enable = true;
            enableDesktop = true;
          };
        };

        programs.zed-editor = {
          inherit (cfg) extensions;

          enable = true;

          mutableUserDebug = false;
          mutableUserKeymaps = false;
          mutableUserSettings = false;
          mutableUserTasks = false;

          userSettings =
            {
              context_servers =
                builtins.mapAttrs (
                  name: mcpServer:
                    if (mcpServer.transport == "stdio")
                    then {
                      inherit (mcpServer) command args;
                      env =
                        builtins.mapAttrs (
                          _: value:
                            if value ? "secret"
                            then "${
                              if value.prefix != null
                              then value.prefix
                              else ""
                            }{env:${value.environmentVariable}}${
                              if value.suffix != null
                              then value.suffix
                              else ""
                            }"
                            else value
                        )
                        mcpServer.env;
                    }
                    else if (mcpServer.transport == "http" || mcpServer.transport == "sse")
                    then let
                      wrapperName = "mcp-proxy-${name}";
                      # Build --headers flags with runtime env var expansion via the shell wrapper.
                      headerFlags = lib.concatStringsSep " \\\n                      " (
                        lib.mapAttrsToList (
                          headerName: value:
                            if value ? "secret"
                            then "--headers '${headerName}' \"${
                              if value.prefix != null
                              then value.prefix
                              else ""
                            }\${${value.environmentVariable}}${
                              if value.suffix != null
                              then value.suffix
                              else ""
                            }\""
                            else "--headers '${headerName}' '${value}'"
                        ) (mcpServer.headers or {})
                      );
                      transportFlag =
                        if mcpServer.transport == "sse"
                        then ""
                        else "--transport streamablehttp";
                      wrapper = pkgs.writeShellScriptBin wrapperName ''
                        exec ${pkgs.mcp-proxy}/bin/mcp-proxy \
                          ${transportFlag} \
                          ${headerFlags} \
                          '${mcpServer.url}'
                      '';
                    in {
                      command = "${wrapper}/bin/${wrapperName}";
                      args = [];
                    }
                    else throw "Unsupported MCP transport: ${mcpServer.transport}"
                )
                editorCfg.mcp;
            }
            // cfg.userSettings;
        };
      }
      (
        let
          editor = pkgs.zed-editor;
        in
          mkIf (options ? sops && allSecrets != []) {
            sops.secrets = genAttrs allSecrets (_: {});

            programs.zed-editor.package = mkForce (
              pkgs.symlinkJoin {
                pname = editor.pname or "zed";
                version = editor.version or "latest";
                name = "${editor.name}-with-secrets";

                paths = [editor];
                buildInputs = [pkgs.makeWrapper];
                postBuild = ''
                  for bin in $out/bin/*; do
                    if [ -f "$bin" ] && [ -x "$bin" ]; then
                      wrapProgram "$bin" \
                        ${concatStringsSep " \\\n" (
                    map (
                      secret: "--run '[ -f ${config.sops.secrets.${secret}.path} ] && export ${baseNameOf secret}=\"$(cat ${
                        config.sops.secrets.${secret}.path
                      })\"'"
                    )
                    allSecrets
                  )}
                    fi
                  done
                '';
              }
            );
          }
      )
    ]);
  }

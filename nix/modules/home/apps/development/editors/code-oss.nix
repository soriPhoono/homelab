{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.apps.development.editors.code-oss;

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

  # Build VS Code profiles from extensionProfiles, filtered by activeProfiles.
  vscodeProfiles = let
    filtered = lib.filterAttrs (name: _: builtins.elem name cfg.activeProfiles) cfg.extensionProfiles;
  in
    (lib.mapAttrs (_: profile: {
        extensions = cfg.common.extensions ++ profile.extensions;
        userSettings = cfg.userSettings // profile.userSettings;
        userTasks = cfg.common.userTasks // profile.userTasks;
        keybindings = cfg.common.keybindings ++ profile.keybindings;
        languageSnippets = cfg.common.languageSnippets // profile.languageSnippets;
        globalSnippets = cfg.common.globalSnippets // profile.globalSnippets;
      })
      filtered)
    // {
      default = {
        extensions = cfg.common.extensions;
        inherit (cfg) userSettings;
        userTasks = cfg.common.userTasks;
        keybindings = cfg.common.keybindings;
        languageSnippets = cfg.common.languageSnippets;
        globalSnippets = cfg.common.globalSnippets;
      };
    };
in
  with lib; {
    options.apps.development.editors.code-oss = removeAttrs (homelab.agentics.mkVscodeEditor {
      name = "code-oss";
      package = pkgs.vscodium;
    }) ["agent"];

    config = mkIf cfg.enable (mkMerge [
      {
        # Default editor — programs.vscode has no defaultEditor option
        home.sessionVariables = mkIf cfg.defaultEditor {
          EDITOR = "${lib.getExe cfg.package}";
          VISUAL = "${lib.getExe cfg.package}";
        };

        # MIME type associations
        xdg.mimeApps.defaultApplications = lib.mkIf config.apps.defaultApplications.enable (
          let
            editor = ["${baseNameOf (lib.getExe cfg.package)}.desktop"];
          in
            mkOverride cfg.priority (
              builtins.listToAttrs (map (mime: lib.nameValuePair mime editor) codeMimeTypes)
            )
        );

        # Extra packages (LSP servers, formatters, linters)
        home.packages = cfg.extraPackages;

        # Delegate to upstream programs.vscodium module
        programs.vscodium = {
          enable = true;
          inherit (cfg) package;
          profiles = vscodeProfiles;
        };
      }

      (mkIf (options ? stylix) {
        stylix.targets.vscodium.profileNames = builtins.attrNames vscodeProfiles;
      })
    ]);
  }

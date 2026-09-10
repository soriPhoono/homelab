_: {
  apps.development.editors.vscode = {
    userSettings = {
      # Editor appearance — font and theme managed by Stylix
      "editor.minimap.enabled" = true;
      "editor.renderWhitespace" = "trailing";
      "editor.cursorBlinking" = "smooth";
      "editor.cursorSmoothCaretAnimation" = "on";
      "editor.smoothScrolling" = true;
      "editor.bracketPairColorization.enabled" = true;
      "editor.guides.indentation" = true;
      "editor.guides.bracketPairs" = true;

      # General UI/UX improvements
      "workbench.startupEditor" = "none";
      "editor.inlineSuggest.enabled" = true;
      "editor.tabCompletion" = "on";
      "workbench.editor.closeOnFileDelete" = false;

      # Formatting
      "editor.formatOnSave" = true;
      "editor.formatOnPaste" = true;
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      # "explicit" (not boolean true) — VS Code migrates booleans on launch,
      # which fails on the read-only nix store symlink and retries every launch.
      "editor.codeActionsOnSave" = {
        "source.fixAll" = "explicit";
        "source.organizeImports" = "explicit";
      };

      # Files
      "files.autoSave" = "afterDelay";
      "files.autoSaveDelay" = 1000;
      "files.trimTrailingWhitespace" = true;
      "files.insertFinalNewline" = true;
      "files.trimFinalNewlines" = true;

      # Search
      "search.exclude" = {
        "**/.direnv" = true;
        "**/result" = true;
        "**/node_modules" = true;
        "**/.git" = true;
      };

      # Terminal — font managed by Stylix; bell silenced via
      # accessibility.signals.terminalBell below (terminal.integrated.enableBell
      # is deprecated — VS Code migrates it away on launch, which fails on the
      # read-only nix store symlink and retries every launch).
      "terminal.integrated.cursorBlinking" = true;

      # Git
      "git.autofetch" = true;
      "git.confirmSync" = false;
      "git.enableSmartCommit" = true;

      # Formatting default formatters
      "[shellscript]" = {
        "editor.defaultFormatter" = "foxundermoon.shell-format";
      };
      "[yaml]" = {
        "editor.defaultFormatter" = "redhat.vscode-yaml";
        "editor.tabSize" = 2;
      };
      "yaml.format.enable" = true;
      "yaml.disableSchemaDetection" = [
        "**/.github/workflows/*.yml"
        "**/.github/workflows/*.yaml"
        "**/.gitea/workflows/*.yml"
        "**/.gitea/workflows/*.yaml"
        "**/.forgejo/workflows/*.yml"
        "**/.forgejo/workflows/*.yaml"
      ];

      # Markdown settings
      "[markdown]" = {
        "editor.wordWrap" = "on";
        "editor.quickSuggestions" = {
          "comments" = "on";
          "strings" = "on";
          "other" = "on";
        };
      };

      # Go/Python/Rust settings
      "[go]" = {
        "editor.defaultFormatter" = "golang.go";
      };
      "[rust]" = {
        "editor.defaultFormatter" = "rust-lang.rust-analyzer";
      };

      # Nix
      "[nix]" = {
        "editor.tabSize" = 2;
        "editor.formatOnSave" = true;
      };

      # Disable extension updates
      "extensions.autoCheckUpdates" = false;
      "extensions.autoUpdate" = "off";
      "accessibility.signals.terminalBell" = {
        "sound" = "off";
      };
    };
  };
}

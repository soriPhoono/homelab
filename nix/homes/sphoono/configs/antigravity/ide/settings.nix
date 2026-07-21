_: {
  apps.development.editors.antigravity = {
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
      "editor.codeActionsOnSave" = {
        "source.fixAll" = true;
        "source.organizeImports" = true;
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

      # Terminal — font managed by Stylix
      "terminal.integrated.cursorBlinking" = true;
      "terminal.integrated.enableBell" = false;

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
      "extensions.autoUpdate" = false;
      "accessibility.signals.terminalBell" = {
        "sound" = "off";
      };
    };
  };
}

_: {
  userapps.development.editors.code-oss = {
    # Common keybindings applied to every active profile.
    # Per-profile keybindings are added in the extensionProfiles.
    common.keybindings = [
      # --- Navigation ---
      {
        key = "ctrl+shift+t";
        command = "workbench.action.terminal.toggleTerminal";
        when = "!terminalFocus";
      }
      {
        key = "ctrl+shift+t";
        command = "workbench.action.terminal.toggleTerminal";
        when = "terminalFocus";
      }
      {
        key = "ctrl+shift+.";
        command = "editor.action.showHover";
        when = "editorTextFocus";
      }
      {
        key = "alt+up";
        command = "editor.action.moveLinesUpAction";
        when = "editorTextFocus && !editorReadonly";
      }
      {
        key = "alt+down";
        command = "editor.action.moveLinesDownAction";
        when = "editorTextFocus && !editorReadonly";
      }
      {
        key = "ctrl+shift+x";
        command = "workbench.view.explorer";
        when = "viewContainer.workbench.view.explorer.enabled";
      }
      {
        key = "ctrl+'";
        command = "workbench.action.splitEditorRight";
      }
      {
        key = "ctrl+shift-'";
        command = "workbench.action.closeEditorsAndGroup";
      }

      # --- Editor ---
      {
        key = "ctrl+shift+f";
        command = "editor.action.formatDocument";
        when = "editorHasDocumentFormattingProvider && editorTextFocus && !editorReadonly";
      }
      {
        key = "ctrl+shift+d";
        command = "editor.action.copyLinesDownAction";
        when = "editorTextFocus && !editorReadonly";
      }
      {
        key = "ctrl+shift+k";
        command = "editor.action.deleteLines";
        when = "editorTextFocus && !editorReadonly";
      }
      {
        key = "ctrl+shift+l";
        command = "editor.action.insertCursorAtEndOfEachLineSelected";
        when = "editorTextFocus";
      }

      # --- Git ---
      {
        key = "ctrl+alt+g";
        command = "workbench.view.scm";
        when = "workbench.scm.active";
      }

      # --- Search ---
      {
        key = "ctrl+shift+r";
        command = "workbench.action.findInFiles";
      }

      # --- Terminal ---
      {
        key = "ctrl+alt+up";
        command = "workbench.action.terminal.resizePaneUp";
        when = "terminalFocus";
      }
      {
        key = "ctrl+alt+down";
        command = "workbench.action.terminal.resizePaneDown";
        when = "terminalFocus";
      }
    ];
  };
}

_: {
  apps.development.editors.antigravity = {
    # Common keybindings applied to every active profile.
    # Per-profile keybindings are added in the extensionProfiles.
    common.keybindings = [
      {
        key = "ctrl+alt+p";
        command = "workbench.profiles.actions.switchProfile";
      }
    ];
  };
}

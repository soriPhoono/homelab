{...}: {
  imports = [
    ./settings.nix
    ./extensions.nix
    ./keybindings.nix
    ./snippets.nix
  ];

  apps.development.editors.antigravity = {
    # Active profiles — switch via VS Code profile picker
    activeProfiles = ["devops" "fullstack" "webdev"];
  };
}

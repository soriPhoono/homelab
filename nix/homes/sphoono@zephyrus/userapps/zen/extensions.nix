{pkgs, ...}: {
  userapps.browsers.zen.profileConfig.default = {
    mods = [
      "f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better Unloaded Tabs
      "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # Better Active Tab
      "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
      "7190e4e9-bead-4b40-8f57-95d852ddc941" # Tab title fixes
      "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
      "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
      "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
      "c8d9e6e6-e702-4e15-8972-3596e57cf398" # Zen Back Forward
      "cb15abdb-0514-4e09-8ce5-722cf1f4a20f" # Hide Extension Name
      "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
    ];

    extensions = {
      packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
        privacy-badger
        decentraleyes
      ];
    };
  };
}

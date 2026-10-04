{
  # A sub-aspect rather than part of sphoono.desktop itself: the base
  # desktop aspect also reaches the standalone home, which should not run
  # Syncthing. Hosts opt in explicitly.
  den.aspects.sphoono.desktop.syncthing = {
    # Syncs ~/Shared (vault, wallpapers, the agent wiki) between desktop-ares
    # and laptop-ares. Devices and folders are paired in the web GUI and kept
    # in ~/.local/state/syncthing, so each host keeps its own keys and no
    # secret enters the config.
    homeManager.services.syncthing = {
      enable = true;
      overrideDevices = false;
      overrideFolders = false;
    };
  };
}

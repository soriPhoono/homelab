_: {
  userapps.desktop.browsers.zen.profileConfig.default = {
    settings = {
      "browser.search.defaultenginename" = "DuckDuckGo";
      "browser.search.order.1" = "DuckDuckGo";

      "zen.workspaces.continue-where-left-off" = true;
      "zen.workspaces.natural-scroll" = true;
      "zen.view.compact.hide-tabbar" = true;
      "zen.view.compact.hide-toolbar" = true;
      "zen.view.compact.animate-sidebar" = true;
      "zen.welcome-screen.seen" = true;
      "zen.urlbar.behavior" = "float";

      "browser.download.dir" = "~/Downloads";
      "browser.download.useDownloadDir" = true;

      "browser.shell.shortcut-backspace" = -1;

      "browser.tabs.insertRelatedAfterCurrent" = true;
      "browser.tabs.unloadOnLowMemory" = true;

      "browser.bookmarks.showMobileBookmarks" = false;

      "full-screen-api.warning.timeout" = 0;
    };

    pinsForce = true;
    pins = {
      "Bitwarden" = {
        id = "a8cdd4e1-5c7b-4f6a-9e8d-c3b2a1f0e9d5";
        url = "https://vault.bitwarden.com/#/vault";
        position = 1;
        isEssential = true;
      };
      "GitHub" = {
        id = "b9d4e2f3-6a8c-4d5e-b7f9-a4c3b2d1e0f6";
        url = "https://github.com";
        position = 2;
        isEssential = true;
      };
      "Google Drive" = {
        id = "c0e5f4a5-7b9d-4e6f-c8a0-b5d4c3e2f1a7";
        url = "https://drive.google.com";
        position = 3;
        isEssential = true;
      };
      "YouTube" = {
        id = "d1f6a5b6-c8e0-4f7a-d9b1-e6c4d3f2a1b8";
        url = "https://youtube.com";
        position = 4;
        isEssential = true;
      };
      "Remix IDE" = {
        id = "e2f7b6c7-d9f1-5a8c-e0b2-f7d5e4c3b2a9";
        url = "https://remix.ethereum.org";
        position = 5;
        isEssential = true;
      };
    };
  };
}

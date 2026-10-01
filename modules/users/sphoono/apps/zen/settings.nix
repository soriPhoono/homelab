{
  den.aspects.sphoono.homeManager = {
    programs.zen-browser.profiles.default = {
      settings = {
        "browser.search.defaultenginename" = "DuckDuckGo";
        "browser.search.order.1" = "DuckDuckGo";
        "browser.startup.page" = 3;

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

        "zen.window-sync.enabled" = true;
        "zen.window-sync.sync-only-pinned-tabs" = true;
      };
    };
  };
}

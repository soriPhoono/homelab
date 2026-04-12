_: {
  userapps.desktop.browsers.zen.extraConfig.policies = let
    mkLockedAttrs = builtins.mapAttrs (_: value: {
      Value = value;
      Status = "locked";
    });
  in {
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;
    DisableAppUpdate = true;
    DisableFeedbackCommands = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableTelemetry = true;
    DontCheckDefaultBrowser = true;
    NoDefaultBookmarks = true;
    OfferToSaveLogins = false;

    EnableTrackingProtection = {
      Value = true;
      Locked = true;
      Cryptomining = true;
      Fingerprinting = true;
    };

    Preferences = mkLockedAttrs {
      "browser.aboutConfig.showWarning" = false;
      "browser.tabs.warnOnClose" = false;
      "browser.newtabpage.activity-stream.feeds.topsites" = false;
      "browser.topsites.contile.enabled" = false;

      "privacy.resistFingerprinting" = true;
      "privacy.resistFingerprinting.randomization.canvas.use_siphash" = true;
      "privacy.resistFingerprinting.randomization.daily_reset.enabled" = true;
      "privacy.resistFingerprinting.randomization.daily_reset.private.enabled" = true;
      "privacy.resistFingerprinting.block_mozAddonManager" = true;
      "privacy.spoof_english" = 1;

      "privacy.firstparty.isolate" = true;
      "network.cookie.cookieBehavior" = 5;
      "dom.battery.enabled" = false;

      "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;

      "browser.gesture.swipe.left" = "";
      "browser.gesture.swipe.right" = "";

      "browser.download.dir" = "~/Downloads";
      "browser.download.useDownloadDir" = true;

      "network.http.http3.enabled" = true;
      "network.socket.ip_addr_any.disabled" = true;
    };
  };
}

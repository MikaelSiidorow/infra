# Firefox configuration
{
  config,
  lib,
  pkgs,
  isDarwin ? false,
  ...
}:
{
  programs.firefox = {
    enable = true;
    package = if isDarwin then pkgs.firefox-bin else config.lib.nixGL.wrap pkgs.firefox;

    profiles.default = {
      isDefault = true;

      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        sponsorblock
        darkreader
        bitwarden
      ];

      settings = {
        # Auto-enable extensions managed by nix
        "extensions.autoDisableScopes" = 0;

        # Performance & memory
        "browser.tabs.unloadOnLowMemory" = true;
        "browser.sessionstore.interval" = 60000; # save session every 60s instead of 15s
        "browser.cache.disk.capacity" = 512000; # 500MB disk cache
        "image.mem.surfacecache.max_size_kb" = 256000; # limit image cache

        # Passwords: disabled — using Bitwarden extension
        "signon.rememberSignons" = false;
        "signon.generation.enabled" = false;
        "signon.autofillForms" = false;
        "signon.management.page.breach-alerts.enabled" = false;
        "signon.firefoxRelay.feature" = "disabled";

        # Privacy
        "browser.contentblocking.category" = "strict";
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        "dom.security.https_only_mode" = true;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "app.shield.optoutstudies.enabled" = false;

        # Vertical tabs (left sidebar)
        "sidebar.verticalTabs" = true;
        "sidebar.revamp" = true;

        # UX
        "browser.shell.checkDefaultBrowser" = false;
        "browser.aboutConfig.showWarning" = false;
        "browser.tabs.closeWindowWithLastTab" = false;
        "browser.toolbars.bookmarks.visibility" = "newtab";
        "browser.startup.page" = 3; # restore previous session
        "browser.tabs.crashReporting.sendReport" = false;

        # Scrolling (smooth, native feel)
        "general.smoothScroll" = true;
        "general.smoothScroll.msdPhysics.enabled" = true;

        # Hardware acceleration
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
      };

      search = {
        default = "google";
        force = true;
        engines = {
          "Nix Packages" = {
            urls = [ { template = "https://search.nixos.org/packages?query={searchTerms}"; } ];
            definedAliases = [ "@np" ];
          };
          "Nix Options" = {
            urls = [ { template = "https://search.nixos.org/options?query={searchTerms}"; } ];
            definedAliases = [ "@no" ];
          };
          "Home Manager Options" = {
            urls = [ { template = "https://home-manager-options.extranix.com/?query={searchTerms}"; } ];
            definedAliases = [ "@hm" ];
          };
        };
      };
    };
  };
}

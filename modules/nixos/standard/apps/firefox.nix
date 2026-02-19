{ pkgs, ... }:
let
  lock-false = {
    Value = false;
    Status = "locked";
  };

  lock-true = {
    Value = true;
    Status = "locked";
  };

  lock-empty-string = {
    Value = "";
    Status = "locked";
  };
in
{
  programs.firefox = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DontCheckDefaultBrowser = true;
      DisablePocket = true;
      SearchBar = "unified";

      Preferences = {
        "general.autoScroll" = lock-true;

        # Privacy settings
        "extensions.pocket.enabled" = lock-false;
        "browser.newtabpage.pinned" = lock-empty-string;
        "browser.topsites.contile.enabled" = lock-false;
        "browser.newtabpage.activity-stream.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
        "middlemouse.paste" = lock-false;

        # Profile settings (previously in home-manager)
        "browser.toolbars.bookmarks.visibility" = {
          Value = "never";
          Status = "locked";
        };
        "dom.events.asyncClipboard.clipboardItem" = lock-true;
        "browser.sessionstore.resume_from_crash" = lock-false;
        "media.ffmpeg.vaapi.enabled" = lock-true;
        "gfx.webrender.all" = lock-true;
        "browser.urlbar.suggest.openpage" = lock-false;
        "browser.tabs.firefox-view" = lock-false;
      };

      # Search engines via policies
      SearchEngines = {
        Default = "Google";
        Add = [
          {
            Name = "Nix Packages";
            URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
            Method = "GET";
            IconURL = "https://nixos.org/favicon.png";
            Alias = "@np";
          }
          {
            Name = "Nix Options";
            URLTemplate = "https://search.nixos.org/options?query={searchTerms}";
            Method = "GET";
            IconURL = "https://nixos.org/favicon.png";
            Alias = "@no";
          }
          {
            Name = "Home Manager Options";
            URLTemplate = "https://home-manager-options.extranix.com/?query={searchTerms}";
            Method = "GET";
            IconURL = "https://nixos.org/favicon.png";
            Alias = "@hm";
          }
          {
            Name = "NixOS Wiki";
            URLTemplate = "https://nixos.wiki/index.php?search={searchTerms}";
            Method = "GET";
            Alias = "@nw";
          }
          {
            Name = "nixpkgs GitHub";
            URLTemplate = "https://github.com/NixOS/nixpkgs/issues?q={searchTerms}";
            Method = "GET";
            Alias = "@nixpkgs";
          }
          {
            Name = "YouTube";
            URLTemplate = "https://www.youtube.com/results?search_query={searchTerms}";
            Method = "GET";
            Alias = "@yt";
          }
          {
            Name = "GitHub";
            URLTemplate = "https://github.com/search?q={searchTerms}";
            Method = "GET";
            Alias = "@gh";
          }
          {
            Name = "docs.rs";
            URLTemplate = "https://docs.rs/releases/search?query={searchTerms}";
            Method = "GET";
            Alias = "@docs";
          }
          {
            Name = "lib.rs";
            URLTemplate = "https://lib.rs/search?q={searchTerms}";
            Method = "GET";
            Alias = "@lib";
          }
        ];
      };

      ExtensionSettings = {
        # ublock
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };

        # 1password
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest";
          installation_mode = "force_installed";
        };

        # wikiwand
        "jid1-D7momAzRw417Ag@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/wikiwand-wikipedia-modernized/latest";
          installation_mode = "force_installed";
        };

        # 7tv
        "moz-addon-prod@7tv.app" = {
          install_url = "https://extension.7tv.gg/v3.0.9/ext.xpi";
          installation_mode = "force_installed";
        };

        # Firefox Color
        "FirefoxColor@mozilla.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/firefox-color/latest.xpi";
          installation_mode = "force_installed";
        };

        # DarkReader
        "addon@darkreader.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          installation_mode = "force_installed";
        };

        # TODO: Catppuccin userstyles (~130 sites) were previously managed via nix-userstyles
        # and injected as userContent CSS through home-manager. To restore:
        # 1. Install the Stylus extension
        # 2. Import catppuccin userstyles manually from https://github.com/catppuccin/userstyles
        # Or add Stylus extension here and manage userstyles through it.

        # TODO: Betterfox preferences were previously applied via betterfox-nix home-manager module.
        # To restore, either:
        # 1. Copy betterfox user.js settings into the Preferences section above
        # 2. Or manually place a user.js file in the Firefox profile directory
        # See: https://github.com/yokoffing/Betterfox
      };
    };
  };
}

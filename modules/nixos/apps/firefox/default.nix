{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.firefox;
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
  options.teevik.apps.firefox = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable firefox
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;

      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DontCheckDefaultBrowser = true;
        DisablePocket = true;
        SearchBar = "unified";

        Preferences = {
          # Privacy settings
          "extensions.pocket.enabled" = lock-false;
          "browser.newtabpage.pinned" = lock-empty-string;
          "browser.topsites.contile.enabled" = lock-false;
          "browser.newtabpage.activity-stream.showSponsored" = lock-false;
          "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
          "middlemouse.paste" = lock-false;
          "browser.fullscreen.autohide" = lock-false;
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

          # # darkreader
          # "addon@darkreader.org" = {
          #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest";
          #   installation_mode = "force_installed";
          # };

          # 7tv
          "moz-addon-prod@7tv.app" = {
            install_url = "https://extension.7tv.gg/v3.0.9/ext.xpi";
            installation_mode = "force_installed";
          };

          "FirefoxColor@mozilla.com" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/firefox-color/latest.xpi";
            installation_mode = "force_installed";
          };

          # "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          #   installation_mode = "force_installed";
          # };
          # "jid1-MnnxcxisBPnSXQ@jetpack" = {
          #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
          #   installation_mode = "force_installed";
          # };
          # "extension@tabliss.io" = {
          #   install_url = "https://addons.mozilla.org/firefox/downloads/file/3940751/tabliss-2.6.0.xpi";
          #   installation_mode = "force_installed";
          # };
        };
      };
    };
  };
}

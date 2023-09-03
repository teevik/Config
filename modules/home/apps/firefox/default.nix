{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.firefox;
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

      profiles.default = {
        settings = {
          browser.toolbars.bookmarks.visibility = "never";
        };

        extensions = with config.nur.repos.rycee.firefox-addons; [
          onepassword-password-manager
          ublock-origin

          (buildFirefoxXpiAddon {
            pname = "everforest-dark";
            version = "2.0";
            addonId = "{c0f86627-5243-4bf4-a522-a41ed12f1737}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4055905/everforest_dark_official-2.0.xpi";
            sha256 = "sha256-xL55Gq9URihK0bS/oKyd/yrSoo4qNRpy2Kv+Vt0VL/g=";
            meta = { };
          })

          (buildFirefoxXpiAddon {
            pname = "catppuccin-mocha-pink";
            version = "old";
            addonId = "{8446b178-c865-4f5c-8ccc-1d7887811ae3}";
            url = "https://github.com/catppuccin/firefox/releases/download/old/catppuccin_mocha_pink.xpi";
            sha256 = "";
            meta = { };
          })
        ];

        search.force = true;

        search.engines = {
          "Nix Packages" = {
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                { name = "type"; value = "packages"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "NixOS Wiki" = {
            urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
            iconUpdateURL = "https://nixos.wiki/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000; # every day
            definedAliases = [ "@nw" ];
          };
        };
      };
    };
  };
}

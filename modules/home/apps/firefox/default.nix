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

          # Required for figma to be able to export to svg
          "dom.events.asyncClipboard.clipboardItem" = true;

          # Do not restore sessions after what looks like a "crash"
          "browser.sessionstore.resume_from_crash" = false;

          "media.ffmpeg.vaapi.enabled" = true;
          "gfx.webrender.all" = true;
        };

        # List of addons: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/generated-firefox-addons.nix
        extensions = with config.nur.repos.rycee.firefox-addons; [
          onepassword-password-manager
          ublock-origin
          wikiwand-wikipedia-modernized

          translate-web-pages
          search-by-image
          darkreader

          (buildFirefoxXpiAddon {
            pname = "everforest-dark";
            version = "2.0";
            addonId = "{c0f86627-5243-4bf4-a522-a41ed12f1737}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4055905/everforest_dark_official-2.0.xpi";
            sha256 = "sha256-xL55Gq9URihK0bS/oKyd/yrSoo4qNRpy2Kv+Vt0VL/g=";
            meta = { };
          })

          # (buildFirefoxXpiAddon {
          #   pname = "catppuccin-mocha-pink";
          #   version = "old";
          #   addonId = "{8446b178-c865-4f5c-8ccc-1d7887811ae3}";
          #   url = "https://github.com/catppuccin/firefox/releases/download/old/catppuccin_mocha_pink.xpi";
          #   sha256 = "sha256-MPaGVZMjqdqbDA7dbiSl5qQ2ji+aKyftLJiISY5ShQI=";
          #   meta = { };
          # })
        ];

        search.force = true;

        search.engines =
          let
            mkBasicSearchEngine = { aliases, url, param, icon ? null }: {
              urls = [{
                template = url;
                params = [
                  { name = param; value = "{searchTerms}"; }
                ];
              }];

              definedAliases = aliases;
            } // (if icon == null then { } else { inherit icon; });
          in
          {
            "Nix Packages" = mkBasicSearchEngine {
              aliases = [ "@np" "@nix-packages" ];
              url = "https://search.nixos.org/packages";
              param = "query";
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            };

            "Nix Options" = mkBasicSearchEngine {
              aliases = [ "@no" "@nix-options" ];
              url = "https://search.nixos.org/options";
              param = "query";
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            };

            "Home Manager Options" = mkBasicSearchEngine {
              aliases = [ "@hm" "@home-manager" ];
              url = "https://home-manager-options.extranix.com";
              param = "query";
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            };

            "NixOS Wiki" = mkBasicSearchEngine {
              aliases = [ "@nw" "@nix-wiki" ];
              url = "https://nixos.wiki/index.php";
              param = "search";
            };

            "Youtube" = mkBasicSearchEngine {
              url = "https://www.youtube.com/results";
              param = "search_query";
              aliases = [ "@yt" "@youtube" ];
            };

            "Github" = mkBasicSearchEngine {
              url = "https://github.com/search";
              param = "q";
              aliases = [ "@gh" "@github" ];
            };

            "docs.rs" = mkBasicSearchEngine {
              url = "https://docs.rs/releases/search";
              param = "query";
              aliases = [ "@docs" "@docs.rs" ];
            };
          };
      };
    };
  };
}

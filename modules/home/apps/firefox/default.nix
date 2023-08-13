{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.firefox;

  materialfox = pkgs.fetchFromGitHub {
    owner = "typeling1578";
    repo = "MaterialFox-Plus";
    rev = "e12f95f0aa4e759dbf76567cfbad45450c675be1";
    hash = "sha256-ir5qDQ0ewHCccpG71uTyUFANw/7W7kX2NfqCttOvxRc=";
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

      profiles.default = {
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "svg.context-properties.content.enabled" = true;
          "browser.tabs.tabClipWidth" = 83;
          "security.insecure_connection_text.enabled" = true;
        };

        userChrome = ''
          @import "${materialfox}/chrome/userChrome.css";
        '';

        # userChrome =
        #   let
        #     includes = "${cascade}/chrome/includes";
        #     integrations = "${cascade}/integrations";
        #   in
        #   lib.strings.concatStrings [
        #     (builtins.readFile "${includes}/cascade-config-mouse.css")
        #     # (builtins.readFile "${integrations}/catppuccin/cascade-mocha.css")
        #     # (builtins.readFile "${includes}/cascade-colours.css")
        #     (builtins.readFile "${includes}/cascade-layout.css")
        #     (builtins.readFile "${includes}/cascade-responsive.css")
        #     (builtins.readFile "${includes}/cascade-floating-panel.css")
        #     (builtins.readFile "${includes}/cascade-nav-bar.css")
        #     (builtins.readFile "${includes}/cascade-tabs.css")
        #   ];

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

{ pkgs, lib, ... }:

let
  # cascade = pkgs.fetchFromGitHub {
  #   owner = "andreasgrafen";
  #   repo = "cascade";
  #   rev = "a89173a67696a8bf43e8e2ac7ed93ba7903d7a70";
  #   hash = "sha256-D4ZZPm/li1Eoo1TmDS/lI2MAlgosNGOOk4qODqIaCes=";
  # };

  cascade = pkgs.fetchFromGitHub {
    owner = "karamanliev";
    repo = "cascade";
    rev = "1f81d4c031f44e5a6fda62e75c75fd123f657ee9";
    hash = "sha256-RVvjeycu9oZn60D2U4RQzfigmR85VPFu/Z6fXy3/W6I=";
  };
in
{
  teevik.home = {
    programs.firefox = {
      enable = false;

      profiles.default = {
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };

        userChrome =
          let
            includes = "${cascade}/chrome/includes";
            integrations = "${cascade}/integrations";
          in
          lib.strings.concatStrings [
            (builtins.readFile "${includes}/cascade-config-mouse.css")
            # (builtins.readFile "${integrations}/catppuccin/cascade-mocha.css")
            # (builtins.readFile "${includes}/cascade-colours.css")
            (builtins.readFile "${includes}/cascade-layout.css")
            (builtins.readFile "${includes}/cascade-responsive.css")
            (builtins.readFile "${includes}/cascade-floating-panel.css")
            (builtins.readFile "${includes}/cascade-nav-bar.css")
            (builtins.readFile "${includes}/cascade-tabs.css")
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

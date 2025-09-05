{
  config,
  pkgs,
  inputs,
  ...
}:
let
  palette = config.teevik.theme.colors.withoutHashtag;
  # https://github.com/catppuccin/userstyles/tree/main/styles
  userStyles = [
    "brave-search"
    "bsky"
    "chatgpt"
    "cinny"
    "duckduckgo"
    "github"
    "google"
    "hacker-news"
    "lobste.rs"
    "nixos-*"
    "npm"
    "ollama"
    "perplexity"
    "reddit"
    "spotify-web"
    "stack-overflow"
    "whatsapp-web"
    "wikipedia"
    "youtube"
  ];
in
{
  imports = [ inputs.betterfox.homeModules.betterfox ];

  programs.firefox.nativeMessagingHosts = [ pkgs.vdhcoapp ];

  programs.firefox = {
    enable = true;
    betterfox = {
      enable = true;

      profiles.default = {
        enableAllSections = true;
      };
    };

    profiles.default = {
      settings = {
        browser.toolbars.bookmarks.visibility = "never";

        # Required for figma to be able to export to svg
        "dom.events.asyncClipboard.clipboardItem" = true;

        # Do not restore sessions after what looks like a "crash"
        "browser.sessionstore.resume_from_crash" = false;

        "media.ffmpeg.vaapi.enabled" = true;
        "gfx.webrender.all" = true;
        "middlemouse.paste" = false;
      };

      search.force = true;

      userContent = ''
        ${builtins.readFile "${inputs.nix-userstyles.packages.${pkgs.system}.mkUserStyles palette
          userStyles
        }"}
      '';

      search.engines =
        let
          mkBasicSearchEngine =
            {
              aliases,
              url,
              param,
              icon ? null,
            }:
            {
              urls = [
                {
                  template = url;
                  params = [
                    {
                      name = param;
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];

              definedAliases = aliases;
            }
            // (if icon == null then { } else { inherit icon; });
        in
        {
          "Nix Packages" = mkBasicSearchEngine {
            aliases = [
              "@np"
              "@nix-packages"
            ];
            url = "https://search.nixos.org/packages";
            param = "query";
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          };

          "Nix Options" = mkBasicSearchEngine {
            aliases = [
              "@no"
              "@nix-options"
            ];
            url = "https://search.nixos.org/options";
            param = "query";
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          };

          "Home Manager Options" = mkBasicSearchEngine {
            aliases = [
              "@hm"
              "@home-manager"
            ];
            url = "https://home-manager-options.extranix.com";
            param = "query";
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          };

          "NixOS Wiki" = mkBasicSearchEngine {
            aliases = [
              "@nw"
              "@nix-wiki"
            ];
            url = "https://nixos.wiki/index.php";
            param = "search";
          };

          "nixpkgs github" = mkBasicSearchEngine {
            aliases = [
              "@nixpkgs"
            ];
            url = "https://github.com/NixOS/nixpkgs/issues";
            param = "q";
          };

          "Youtube" = mkBasicSearchEngine {
            url = "https://www.youtube.com/results";
            param = "search_query";
            aliases = [
              "@yt"
              "@youtube"
            ];
          };

          "Github" = mkBasicSearchEngine {
            url = "https://github.com/search";
            param = "q";
            aliases = [
              "@gh"
              "@github"
            ];
          };

          "docs.rs" = mkBasicSearchEngine {
            url = "https://docs.rs/releases/search";
            param = "query";
            aliases = [
              "@docs"
              "@docs.rs"
            ];
          };

          "lib.rs" = mkBasicSearchEngine {
            url = "https://lib.rs/search";
            param = "q";
            aliases = [
              "@lib"
            ];
          };
        };
    };
  };
}

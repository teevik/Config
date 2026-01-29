{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.teevik.firefox;
  palette = config.teevik.theme.colors.withoutHashtag;

  # https://github.com/catppuccin/userstyles/tree/main/styles
  userStyles = [
    "advent-of-code"
    "alacritty.org"
    "alternativeto"
    "amplenote"
    "anilist"
    "anonymous-overflow"
    "arch-wiki"
    "boringproxy"
    "brave-search"
    "bsky"
    "bstats"
    "canvas-lms"
    "chatgpt"
    "chatreplay"
    # "chess.com" # build error: @lastMoveColor undefined
    "cinny"
    "claude"
    "cobalt"
    "codeberg"
    "crates.io"
    "crowdin"
    "deepl"
    "deepseek"
    "desmos"
    "devdocs"
    "dev.to"
    "docs.deno.com"
    "docs.rs"
    "duckduckgo"
    "ecosia"
    "elk"
    "formative"
    "freedesktop"
    "ghostty.org"
    "github"
    "gleam.run"
    "gmail"
    "go.dev"
    "google"
    "google-drive"
    "google-gemini"
    "google-photos"
    "grabify"
    "graphite"
    "hackage"
    "hacker-news"
    "have-i-been-pwned"
    "holodex"
    "home-manager-options-search"
    "homepage"
    "hoogle"
    "hoppscotch"
    "hyperpipe"
    "ichi.moe"
    "indie-wiki-buddy"
    "inoreader"
    "instagram"
    "invidious"
    "invokeai"
    "jisho"
    "keybr.com"
    "keyoxide"
    "lastfm"
    "learn-x-in-y-minutes"
    "lemmy"
    "libreddit"
    # "lichess" # build error: @lastMoveColor undefined
    "lingva"
    "linkedin"
    "listenbrainz"
    "lobste.rs"
    "mastodon"
    "mdbook"
    "mdn"
    "migadu-webmail"
    "minesweeper"
    "modrinth"
    "mullvad-leta"
    "namemc"
    "neovim.io"
    "nitter"
    "nixos-manual"
    "nixos-search"
    "npm"
    "ollama"
    "openmediavault"
    "paste.rs"
    "perplexity"
    "phanpy"
    "picrew"
    "pinterest"
    "planet-minecraft"
    "poe"
    "porkbun"
    "pronouns.cc"
    "pronouns.page"
    "proton"
    "pypi"
    "pythonanywhere"
    "quizlet"
    "raindrop"
    "react.dev"
    "reddit"
    "regex101"
    "rentry.co"
    "searchix"
    "searxng"
    "seventv"
    "shinigami-eyes"
    "snapchat-web"
    "spotify-web"
    "stack-overflow"
    "startpage"
    "status.cafe"
    "stylus"
    "substack"
    "syncthing"
    "tabnews"
    "tldraw"
    "trinket"
    "tuta"
    "twitch"
    "twitter"
    "vercel"
    "vikunja"
    "web.dev"
    "whatsapp-web"
    "wiki.nixos.org"
    "wikipedia"
    "wikiwand"
    "youtube"
    "zen-browser-docs"
  ];
in
{
  imports = [ inputs.betterfox.homeModules.betterfox ];

  options.teevik.firefox = {
    enableUserStyles = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable catppuccin userstyles for Firefox. Disable to avoid IFD during cross-architecture evaluation.";
    };
  };

  config.programs.firefox = {
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
        "browser.urlbar.suggest.openpage" = false; # Don't suggest open tabs
        "browser.tabs.firefox-view" = false; # Don't show Firefox View
      };

      search.force = true;

      # Userstyles trigger IFD which fails during cross-architecture evaluation
      userContent = lib.mkIf cfg.enableUserStyles (
        builtins.readFile (inputs.nix-userstyles.packages.${pkgs.system}.mkUserStyles palette userStyles)
      );

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

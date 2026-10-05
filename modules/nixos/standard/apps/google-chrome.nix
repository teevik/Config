{ pkgs, ... }:
let
  # Chrome Web Store IDs, force-installed through ExtensionInstallForcelist
  extensions = {
    # Theme
    catppuccin-mocha = "bkkmolkhemgaeaeggcmfbghljjjoofoh";
    # Catppuccin userstyles for sites, import once from
    # https://github.com/catppuccin/userstyles/releases/download/all-userstyles-export/import.json
    stylus = "clngdbkpkpeebahjckkjfobafhncgmne";

    ublock-origin-lite = "ddkjiahejlhfcafbddmgiahcphecmpfh";
    onepassword = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
    wikiwand = "emffkefkbkpkgpdeeooapgaicgmcbolj";
    zotero-connector = "ekhagklcjbdpajgpjgmbionohlpdbjgc";
    obsidian-web-clipper = "cnjifjpddelmedmihgijeibhnjfabmlf";
    sponsorblock = "mnjggcdmjocbbbhaepdhchncahnbgone";

    # Twitch and Kick
    seventv = "ammjkodgmmoknidbanneddgankgfejfh";
    nipahtv = "bjggmgekoncaaalaalhchepgkjoahjln";
    # Routes Twitch playlist requests through ad-free proxies
    ttv-lol-pro = "bpaoeijjlplfjbagceilcgbkcdjbomjd";
  };

  siteSearch = name: shortcut: url: { inherit name shortcut url; };

  policies = {
    ExtensionInstallForcelist = map (id: "${id};https://clients2.google.com/service/update2/crx") (
      builtins.attrValues extensions
    );

    MetricsReportingEnabled = false;
    UrlKeyedAnonymizedDataCollectionEnabled = false;
    DefaultBrowserSettingEnabled = false;
    PromotionsEnabled = false;
    # 1Password handles passwords and autofill
    PasswordManagerEnabled = false;
    AutofillCreditCardEnabled = false;
    AutofillAddressEnabled = false;

    BookmarkBarEnabled = false;
    HardwareAccelerationModeEnabled = true;
    # Local and Tailscale services are plain http
    HttpsUpgradesEnabled = false;
    HttpsOnlyMode = "allowed";

    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "Google";
    DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?client=chrome&q={searchTerms}";

    # Type the shortcut then Tab in the address bar
    SiteSearchSettings = [
      (siteSearch "Nix Packages" "np" "https://search.nixos.org/packages?query={searchTerms}")
      (siteSearch "Nix Options" "no" "https://search.nixos.org/options?query={searchTerms}")
      (siteSearch "Home Manager Options" "hm"
        "https://home-manager-options.extranix.com/?query={searchTerms}"
      )
      (siteSearch "NixOS Wiki" "nw" "https://nixos.wiki/index.php?search={searchTerms}")
      (siteSearch "nixpkgs GitHub" "nixpkgs" "https://github.com/NixOS/nixpkgs/issues?q={searchTerms}")
      (siteSearch "YouTube" "yt" "https://www.youtube.com/results?search_query={searchTerms}")
      (siteSearch "GitHub" "gh" "https://github.com/search?q={searchTerms}")
      (siteSearch "docs.rs" "docs" "https://docs.rs/releases/search?query={searchTerms}")
      (siteSearch "lib.rs" "lib" "https://lib.rs/search?q={searchTerms}")
    ];
  };
in
{
  environment.systemPackages = [
    (pkgs.google-chrome.override {
      # VA-API decode on Wayland, so Twitch/Kick streams don't decode on the CPU.
      # Repeating --enable-features replaces the wrapper's, so keep its WaylandWindowDecorations
      commandLineArgs = "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,AcceleratedVideoEncoder,WaylandWindowDecorations";
    })
  ];

  environment.etc."opt/chrome/policies/managed/policies.json".text = builtins.toJSON policies;
}

{
  perSystem,
  pkgs,
  ...
}:
let
  upstream = perSystem.llm-agents.t3code;
  providerPackages = [
    perSystem.llm-agents.codex
    perSystem.llm-agents.claude-code
  ];
  upstreamUnwrapped = (upstream.unwrapped or upstream).override {
    # Stable T3 Code is pinned to an older Electron; nightlies track nixpkgs'
    # current Electron instead.
    electron_43 = pkgs.electron;
  };

  version = "0.0.39-nightly.20260904.1277";

  src = pkgs.fetchFromGitHub {
    owner = "pingdotgg";
    repo = "t3code";
    tag = "v${version}";
    hash = "sha256-O01785Di+s/RxanONwHAwVXLnyxwdfW9Oq8dBSm8O8I=";
  };

  resourceMonitor = pkgs.rustPlatform.buildRustPackage {
    pname = "t3code-resource-monitor";
    inherit version src;
    sourceRoot = "${src.name}/native/resource-monitor";
    cargoHash = "sha256-5cmG2daM1bVOA23gjjoalbx0fEL1hmqV6WZov0sUZp8=";
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    pnpm = pkgs.pnpm_11;
    pname = "t3code";
    inherit version src;
    inherit (upstreamUnwrapped) pnpmWorkspaces;
    fetcherVersion = 4;
    hash = "sha256-A9llQc6umnGZTNlvzG7yt+qu39scGHho8Xvf0vScLtU=";
  };

  nightlyUnwrapped = upstreamUnwrapped.overrideAttrs (oldAttrs: {
    inherit
      version
      src
      pnpmDeps
      resourceMonitor
      ;

    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.pkg-config
    ];

    buildInputs = (oldAttrs.buildInputs or [ ]) ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.libsecret
    ];

    # The upstream derivation interpolates its stable version into preBuild
    # before overrideAttrs runs, so update that embedded argument as well.
    preBuild = builtins.replaceStrings [ upstreamUnwrapped.version ] [ version ] oldAttrs.preBuild;

    installPhase =
      builtins.replaceStrings [ "${upstreamUnwrapped.resourceMonitor}" ] [ "${resourceMonitor}" ]
        oldAttrs.installPhase;

    passthru = (oldAttrs.passthru or { }) // {
      # Exposed as a subpackage so nix-update refreshes its Cargo vendor hash.
      inherit resourceMonitor;
    };

    meta = oldAttrs.meta // {
      changelog = "https://github.com/pingdotgg/t3code/releases/tag/v${version}";
    };
  });

  nightly =
    if upstream ? unwrapped then
      (upstream.override {
        t3code-unwrapped = nightlyUnwrapped;
        inherit providerPackages;
      }).overrideAttrs (oldAttrs: {
        # The wrapper exposes these build inputs through passthru. Define them
        # here so nix-update sees this editable file as their source position.
        passthru = (oldAttrs.passthru or { }) // {
          inherit (nightlyUnwrapped) pnpmDeps resourceMonitor src;
          unwrapped = nightlyUnwrapped;
        };
      })
    else
      nightlyUnwrapped;
in
nightly

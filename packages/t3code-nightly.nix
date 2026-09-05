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

  version = "0.0.39-nightly.20260905.1285";

  src = pkgs.fetchFromGitHub {
    owner = "pingdotgg";
    repo = "t3code";
    tag = "v${version}";
    hash = "sha256-3r4c2khUpwyIipdyVtyGGlXZ5q8RHK9VvTVsDZz0lUI=";
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
    hash = "sha256-mgRMeBpJmiTat38APyE4guNJ+6RiQhenphP7tRcmc+k=";
  };

  nightlyUnwrapped = upstreamUnwrapped.overrideAttrs (oldAttrs: {
    inherit
      version
      src
      pnpmDeps
      resourceMonitor
      ;

    # New nightlies build a libsecret helper that the inherited stable
    # derivation neither has build inputs for nor installs.
    nativeBuildInputs =
      (oldAttrs.nativeBuildInputs or [ ])
      ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.pkg-config
      ];

    buildInputs =
      (oldAttrs.buildInputs or [ ])
      ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.libsecret
      ];

    # The upstream derivation interpolates its stable version into preBuild
    # before overrideAttrs runs, so update that embedded argument as well.
    preBuild = builtins.replaceStrings [ upstreamUnwrapped.version ] [ version ] oldAttrs.preBuild;

    installPhase =
      builtins.replaceStrings [ "${upstreamUnwrapped.resourceMonitor}" ] [ "${resourceMonitor}" ]
        oldAttrs.installPhase;

    postInstall =
      (oldAttrs.postInstall or "")
      + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        install -Dm755 native/browser-secret/build/${pkgs.stdenv.hostPlatform.node.arch}/t3-browser-secret \
          "$desktop/libexec/t3code/apps/desktop/prod-resources/browser-secret/t3-browser-secret"
      '';

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
      }).overrideAttrs
        (oldAttrs: {
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

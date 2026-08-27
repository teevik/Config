{
  perSystem,
  pkgs,
  ...
}:
let
  upstream = perSystem.llm-agents.t3code;
  upstreamUnwrapped = upstream.unwrapped or upstream;

  version = "0.0.36-nightly.20260827.1205";

  src = pkgs.fetchFromGitHub {
    owner = "pingdotgg";
    repo = "t3code";
    tag = "v${version}";
    hash = "sha256-OUMpX1v/3OvKPFeAbkKIqnSKgAmxXT+1rjfNwlwIe+I=";
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
    hash = "sha256-y/sJIluwbn65APmJ2p07FK1ScXpetCloTHtQzZMchDU=";
  };

  nightlyUnwrapped = upstreamUnwrapped.overrideAttrs (oldAttrs: {
    inherit
      version
      src
      pnpmDeps
      resourceMonitor
      ;

    patches = (oldAttrs.patches or [ ]) ++ [
      (pkgs.fetchurl {
        # Temporary workaround for pingdotgg/t3code#523.
        url = "https://github.com/user-attachments/files/30247737/t3code.patch";
        hash = "sha256-pgtPTxdLSWGnyCEYBzbG7nfK1ZnfbrI99lz6rjH+L2k=";
      })
    ];

    # The patch was written for T3 Code 0.0.31. Current nightlies renamed this
    # Schema helper, so temporarily restore the old spelling while applying it.
    prePatch = (oldAttrs.prePatch or "") + ''
      substituteInPlace apps/server/src/provider/Layers/CursorAdapter.ts \
        --replace-fail \
          'Schema.fromJsonString(Schema.Unknown)' \
          'Schema.UnknownFromJsonString'
    '';

    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace apps/server/src/provider/Layers/CursorAdapter.ts \
        --replace-fail \
          'Schema.UnknownFromJsonString' \
          'Schema.fromJsonString(Schema.Unknown)'
    '';

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
      (upstream.override { t3code-unwrapped = nightlyUnwrapped; }).overrideAttrs (oldAttrs: {
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

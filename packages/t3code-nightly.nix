{
  perSystem,
  pkgs,
  ...
}:
let
  version = "0.0.34-nightly.20260812.1077";

  src = pkgs.fetchFromGitHub {
    owner = "pingdotgg";
    repo = "t3code";
    tag = "v${version}";
    hash = "sha256-gXagBH3aQeNbt1EqGgk0zkJmXiRF8iiMVW6XHkZ6Y0o=";
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
    inherit (perSystem.llm-agents.t3code) pnpmWorkspaces;
    fetcherVersion = 4;
    hash = "sha256-KxsxNNo/WU0pBy7lqwxU1OGQtZA7agTppPSGF3CCogw=";
  };
in
perSystem.llm-agents.t3code.overrideAttrs (oldAttrs: {
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
  preBuild =
    builtins.replaceStrings [ perSystem.llm-agents.t3code.version ] [ version ]
      oldAttrs.preBuild;

  installPhase =
    builtins.replaceStrings
      [ "${perSystem.llm-agents.t3code.resourceMonitor}" ]
      [ "${resourceMonitor}" ]
      oldAttrs.installPhase;

  passthru = (oldAttrs.passthru or { }) // {
    # Exposed as a subpackage so nix-update refreshes its Cargo vendor hash.
    inherit resourceMonitor;
  };

  meta = oldAttrs.meta // {
    changelog = "https://github.com/pingdotgg/t3code/releases/tag/v${version}";
  };
})

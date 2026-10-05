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
  # The default alias can lag a major behind even when nixpkgs already ships
  # the runtime required by nightlies. Sort names without evaluating old,
  # removed aliases, and resolve only the newest versioned package.
  electronPackages = pkgs.lib.naturalSort (
    builtins.filter (name: builtins.match "electron_[0-9]+" name != null) (builtins.attrNames pkgs)
  );
  electron = pkgs.${pkgs.lib.last electronPackages};
  upstreamUnwrapped = (upstream.unwrapped or upstream).override (
    args:
    let
      electronArgs = builtins.filter (name: builtins.match "electron(_[0-9]+)?" name != null) (
        builtins.attrNames args
      );
    in
    assert pkgs.lib.assertMsg (
      builtins.length electronArgs == 1
    ) "t3code-nightly: expected one upstream Electron argument";
    # Follow upstream's argument name when stable T3 Code changes majors too.
    pkgs.lib.genAttrs electronArgs (_: electron)
  );
  cppRuntime = pkgs.lib.getLib (upstreamUnwrapped.stdenv or pkgs.stdenv).cc.cc;

  version = "0.0.46-nightly.20261005.2667";

  src = pkgs.fetchFromGitHub {
    owner = "pingdotgg";
    repo = "t3code";
    tag = "v${version}";
    hash = "sha256-M8Ya6b+/YbDrpQjDboMOj/LTLy4UUQg2+rRSNG9GYcQ=";
  };

  # Upstream generates notices from a pinned SPDX revision. Fetch its cache
  # separately so the application build stays offline; nix-update refreshes
  # this hash whenever the nightly changes the revision or required licenses.
  licenseNotices = pkgs.stdenvNoCC.mkDerivation {
    pname = "t3code-license-notices";
    inherit version src;
    nativeBuildInputs = [
      pkgs.nodejs_24
      pkgs.cacert
    ];
    buildPhase = ''
      runHook preBuild
      node scripts/sync-third-party-license-notices.ts
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      cp -r .generated/third-party-licenses "$out"
      runHook postInstall
    '';
    dontFixup = true;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-yMRQkeJHLv9BWMpDV2Dc57n41fQvM4GUM5I9ljnah0c=";
  };

  resourceMonitor = pkgs.rustPlatform.buildRustPackage {
    pname = "t3code-resource-monitor";
    inherit version src;
    sourceRoot = "${src.name}/native/resource-monitor";
    cargoHash = "sha256-5cmG2daM1bVOA23gjjoalbx0fEL1hmqV6WZov0sUZp8=";
  };

  hyprlandCapture = pkgs.rustPlatform.buildRustPackage {
    pname = "t3code-hyprland-capture";
    inherit version src;
    sourceRoot = "${src.name}/native/hyprland-snap-shot";
    cargoLock.lockFile = "${src}/native/hyprland-snap-shot/Cargo.lock";
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    pnpm = pkgs.pnpm_11;
    pname = "t3code";
    inherit version src;
    inherit (upstreamUnwrapped) pnpmWorkspaces;
    fetcherVersion = 4;
    hash = "sha256-WZSV8+ugCLfls7jW7hPFoL4wYAffpER71zt2VhaTVzQ=";
  };

  nightlyUnwrapped = upstreamUnwrapped.overrideAttrs (oldAttrs: {
    inherit
      version
      src
      pnpmDeps
      resourceMonitor
      ;

    postPatch = (oldAttrs.postPatch or "") + ''
      # Upstream seeds this cache with SPDX symlinks into the Nix store.
      # Replace it with the nightly cache instead of copying over those links.
      rm -rf .generated/third-party-licenses
      mkdir -p .generated/third-party-licenses
      cp -r ${licenseNotices}/. .generated/third-party-licenses/
    '';

    # New nightlies build a libsecret helper that the inherited stable
    # derivation neither has build inputs for nor installs.
    nativeBuildInputs =
      (oldAttrs.nativeBuildInputs or [ ])
      ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.pkg-config
        pkgs.patchelf
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

        # Capture setup copies this bundled helper into the user's data home.
        install -Dm755 ${hyprlandCapture}/bin/t3-hyprland-snap-shot \
          "$desktop/libexec/t3code/apps/desktop/prod-resources/hyprland-capture/t3-hyprland-snap-shot"
        cp -r native/hyprland-snap-shot/protocols \
          "$desktop/libexec/t3code/apps/desktop/prod-resources/hyprland-capture/protocols"

        # Stock Electron reports isPackaged=false and setup uses the native
        # build path under appRoot. It requires a regular file, not a symlink.
        install -Dm755 ${hyprlandCapture}/bin/t3-hyprland-snap-shot \
          "$desktop/libexec/t3code/native/hyprland-snap-shot/target/release/t3-hyprland-snap-shot"
      '';

    # Electron does not preload libstdc++ like Node.js does. The vendored tree
    # skips ELF fixup, so give the installed host addon an explicit library path.
    postFixup =
      (oldAttrs.postFixup or "")
      + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        patchelf --add-rpath ${cppRuntime}/lib \
          "$out/libexec/t3code/apps/server/node_modules/node-pty/prebuilds/linux-${pkgs.stdenv.hostPlatform.node.arch}/pty.node"
      '';

    postInstallCheck =
      (oldAttrs.postInstallCheck or "")
      +
        pkgs.lib.optionalString
          (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform)
          ''
            test -x "$desktop/libexec/t3code/apps/desktop/prod-resources/hyprland-capture/t3-hyprland-snap-shot"
            env -u LD_LIBRARY_PATH ELECTRON_RUN_AS_NODE=1 \
              T3CODE_PACKAGE_ROOT="$out" T3CODE_TEST_SHELL=${pkgs.stdenv.shell} \
              ${pkgs.lib.getExe electron} ${../tests/t3code-native.cjs}
            T3CODE_DESKTOP_ROOT="$desktop" \
              ${pkgs.lib.getExe pkgs.nodejs_24} ${../tests/t3code-hyprland.cjs}
          '';

    passthru = (oldAttrs.passthru or { }) // {
      inherit electron hyprlandCapture;
      # Exposed as subpackages so nix-update refreshes both dependency hashes.
      inherit licenseNotices resourceMonitor;
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
            inherit (nightlyUnwrapped)
              hyprlandCapture
              licenseNotices
              pnpmDeps
              resourceMonitor
              src
              ;
            unwrapped = nightlyUnwrapped;
          };
        })
    else
      nightlyUnwrapped;
in
nightly

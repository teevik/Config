{ pkgs, ... }:
let
  inherit (pkgs)
    lib
    stdenv
    fetchFromGitHub
    bun
    pkg-config
    openssl
    makeWrapper
    cacert
    git
    libiconv
    rustPlatform
    ;

  pname = "oh-my-pi";
  version = "13.2.1";

  src = fetchFromGitHub {
    owner = "can1357";
    repo = "oh-my-pi";
    tag = "v${version}";
    hash = "sha256-ph98YH/RNFY87yS5o+i4qeT3j9IVCAnDC7eShCR+5GQ=";
    fetchSubmodules = true;
  };

  # Pre-fetch bun dependencies as a fixed-output derivation
  bunDeps = stdenv.mkDerivation {
    name = "${pname}-${version}-bun-deps";
    inherit src;

    nativeBuildInputs = [
      bun
      cacert
      git
    ];

    dontConfigure = true;
    dontFixup = true;

    # Impure env vars needed for network access in FOD
    impureEnvVars = lib.fetchers.proxyImpureEnvVars;

    buildPhase = ''
      runHook preBuild
      export HOME=$(mktemp -d)

      # Install all workspace dependencies
      bun install --no-progress

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out

      # Copy entire source tree with installed node_modules
      # This preserves bun's workspace symlink structure
      cp -a node_modules $out/node_modules

      # Also copy workspace package node_modules
      for dir in packages/*/node_modules; do
        if [ -d "$dir" ]; then
          pkg_name=$(dirname "$dir" | sed 's|packages/||')
          mkdir -p "$out/workspace/$pkg_name"
          cp -a "$dir" "$out/workspace/$pkg_name/node_modules"
        fi
      done

      runHook postInstall
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-b9gFjRhP0Wa9AtdsWNb/nPVlQQH0k8j7D1O2AIywqtY=";
  };

  # Pre-fetch Cargo dependencies
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-CdCPcSxYtt+wptEUe8bW2iQsllgaxDK2lxvNUborrUw=";
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    bun
    pkgs.cargo
    pkgs.rustc
    pkg-config
    makeWrapper
    cacert
    git
  ];

  buildInputs = [
    openssl
    libiconv
  ]
  ++ lib.optionals stdenv.isDarwin (
    with pkgs.darwin.apple_sdk.frameworks;
    [
      Security
      CoreFoundation
      SystemConfiguration
      CoreServices
    ]
  );

  dontConfigure = true;
  dontStrip = true;

  env = {
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    # Allow nightly features on stable rustc
    RUSTC_BOOTSTRAP = "1";
  };

  preBuild = ''
    export HOME=$(mktemp -d)

    git config --global user.email "nix@localhost"
    git config --global user.name "Nix Build"
    git config --global init.defaultBranch main

    # Use pre-fetched bun dependencies (preserve symlinks)
    cp -a ${bunDeps}/node_modules ./node_modules
    chmod -R u+w node_modules

    # Restore workspace package node_modules
    if [ -d "${bunDeps}/workspace" ]; then
      for dir in ${bunDeps}/workspace/*/node_modules; do
        pkg_name=$(basename $(dirname "$dir"))
        if [ -d "packages/$pkg_name" ]; then
          cp -a "$dir" "packages/$pkg_name/node_modules"
          chmod -R u+w "packages/$pkg_name/node_modules"
        fi
      done
    fi

    # Set up Cargo to use vendored dependencies
    export CARGO_HOME=$(mktemp -d)
    mkdir -p $CARGO_HOME
    mkdir -p .cargo
    cat > .cargo/config.toml <<EOF
    [source.crates-io]
    replace-with = "vendored-sources"

    [source.vendored-sources]
    directory = "${cargoDeps}"
    EOF
  '';

  buildPhase = ''
    runHook preBuild

    echo "Building native Rust module..."
    cd packages/natives
    bun run build:native
    cd ../..

    echo "Generating docs index..."
    bun --cwd=packages/coding-agent run generate-docs-index

    echo "Building omp binary using official build:binary script..."
    bun --cwd=packages/coding-agent run build:binary

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    if [ -f packages/coding-agent/dist/omp ]; then
      cp packages/coding-agent/dist/omp $out/bin/omp
    elif [ -f omp ]; then
      cp omp $out/bin/omp
    else
      echo "ERROR: Binary not found at packages/coding-agent/dist/omp or ./omp"
      find . -name "omp" -type f 2>/dev/null
      exit 1
    fi

    chmod +x $out/bin/omp

    runHook postInstall
  '';

  meta = with lib; {
    description = "AI coding agent for the terminal";
    homepage = "https://github.com/can1357/oh-my-pi";
    license = licenses.mit;
    mainProgram = "omp";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}

{ inputs, pkgs, ... }:
let
  openconnect = pkgs.callPackage "${inputs.openconnect-sso}/nix/openconnect.nix" { };
  project = pkgs.lib.importTOML "${inputs.openconnect-sso}/pyproject.toml";
in
# Upstream poetry2nix predates the Python build API and license operators in
# current nixpkgs. Build the same pinned source with nixpkgs' Python packages.
pkgs.python3Packages.buildPythonApplication {
  pname = "openconnect-sso";
  version = project.tool.poetry.version;
  src = inputs.openconnect-sso;
  # Current nixpkgs removed Qt5 WebEngine and uses Python 3.14.
  patches = [ ./openconnect-sso-qt6.patch ];
  pyproject = true;
  build-system = [ pkgs.python3Packages.poetry-core ];

  dependencies = with pkgs.python3Packages; [
    attrs
    colorama
    keyring
    lxml
    prompt-toolkit
    pyotp
    pyqt6
    pyqt6-webengine
    pysocks
    pyxdg
    requests
    setuptools
    structlog
    toml
  ];
  nativeBuildInputs = [ pkgs.qt6.wrapQtAppsHook ];
  buildInputs = [
    openconnect
    pkgs.qt6.qtwayland
  ];
  dontWrapQtApps = true;
  preFixup = ''
    makeWrapperArgs+=(
      --prefix PATH : ${pkgs.lib.makeBinPath [ openconnect ]}
      --unset QT_PLUGIN_PATH
      "''${qtWrapperArgs[@]}"
      --set QT_STYLE_OVERRIDE Fusion
    )
  '';
  pythonImportsCheck = [
    "openconnect_sso.cli"
    "openconnect_sso.browser.webengine_process"
  ];
  nativeCheckInputs = with pkgs.python3Packages; [
    pytestCheckHook
    pytest-asyncio
    pytest-httpserver
    pytest-timeout
  ];
  doCheck = true;
  pytestFlags = [
    "--asyncio-mode=auto"
    "--timeout=60"
  ];
  preCheck = ''
    export XDG_CONFIG_HOME="$TMPDIR/openconnect-config"
    export XDG_CACHE_HOME="$TMPDIR/openconnect-cache"
    export XDG_DATA_HOME="$TMPDIR/openconnect-data"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
    export QT_QPA_PLATFORM=offscreen
    export QTWEBENGINE_DISABLE_SANDBOX=1
    export QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu"
  '';

  meta = {
    description = "OpenConnect wrapper supporting SAML authentication";
    homepage = "https://github.com/active-group/openconnect-sso";
    license = pkgs.lib.licenses.gpl3Only;
    mainProgram = "openconnect-sso";
    platforms = pkgs.lib.platforms.linux;
  };
}

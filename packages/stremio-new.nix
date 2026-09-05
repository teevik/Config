{
  pkgs,
  ...
}:

let
  inherit (pkgs)
    lib
    rustPlatform
    fetchFromGitHub
    openssl
    pkg-config
    gtk4
    mpv
    libappindicator
    makeWrapper
    nodejs
    libxkbcommon
    libGL
    libdrm
    libx11
    libsoup_3
    webkitgtk_6_0
    libadwaita
    libepoxy
    gettext
    ; # libcef
  # cef-rs expects a specific directory layout
  # Copied from https://github.com/NixOS/nixpkgs/pull/428206 because im lazy
  # cef-path = stdenv.mkDerivation {
  #   pname = "cef-path";
  #   version = libcef.version;
  #   dontUnpack = true;
  #   installPhase = ''
  #     mkdir -p "$out"
  #     find ${libcef}/lib -type f -name "*" -exec cp {} $out/ \;
  #     find ${libcef}/libexec -type f -name "*" -exec cp {} $out/ \;
  #     cp -r ${libcef}/share/cef/* $out/
  #     mkdir -p "$out/include"
  #     cp -r ${libcef}/include/* "$out/include/"
  #   '';
  #   postFixup = ''
  #     strip $out/*.so*
  #   '';
  # };

in
rustPlatform.buildRustPackage {
  name = "stremio-linux-shell";

  src = fetchFromGitHub {
    owner = "Stremio";
    repo = "stremio-linux-shell";
    rev = "28fc1cf2d3aba97c5bdd4599a269cf4e241a687a";
    hash = "sha256-cOD9sjgyZMBG7kj3J3QqIYwHr4hEckPCZ4BwFenoTvQ=";
  };

  cargoHash = "sha256-f4TpTqejR55KPSGUi47UGtHgQESUC4tnwCruy7ZfdrY=";

  # The build scripts tries to download CEF binaries by default.
  # Probably overkill since setting CEF_PATH should skip downloading binaries.
  # buildFeatures = [ "offline-build" ];

  buildInputs = [
    openssl
    gtk4
    mpv
    # libcef
    libGL
    libdrm
    libx11
    libsoup_3
    webkitgtk_6_0
    libadwaita
    libepoxy
  ];

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    gettext
  ];

  # Stremio currently downloads server.js into XDG_DATA_DIR at runtime.

  postInstall = ''
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/scalable/apps

    mv $out/bin/stremio-linux-shell $out/bin/stremio
    cp $src/data/com.stremio.Stremio.desktop $out/share/applications/com.stremio.Stremio.desktop
    cp $src/data/icons/com.stremio.Stremio.svg $out/share/icons/hicolor/scalable/apps/com.stremio.Stremio.svg


    wrapProgram $out/bin/stremio \
       --set LC_NUMERIC C \
       --set-default XCOMPOSEFILE ${libx11}/share/X11/locale/en_US.UTF-8/Compose \
       --prefix LD_LIBRARY_PATH : ${
         lib.makeLibraryPath [
           libappindicator
           libxkbcommon
           openssl
           gtk4
           mpv
           # libcef
           libGL
           libdrm
           libx11
           libsoup_3
           webkitgtk_6_0
           libadwaita
           libepoxy
         ]
       } \
      --suffix LD_LIBRARY_PATH : /run/opengl-driver/lib \
      --suffix LD_LIBRARY_PATH : /run/opengl-driver-32/lib \
       --prefix PATH : ${lib.makeBinPath [ nodejs ]}'';

  # env.CEF_PATH = cef-path;

  meta = {
    mainProgram = "stremio";
    description = "Modern media center that gives you the freedom to watch everything you want";
    homepage = "https://www.stremio.com/";
    # (Server-side) 4.x versions of the web UI are closed-source
    license = with lib.licenses; [
      gpl3Only
      # server.js is unfree
      unfree
    ];
    maintainers = with lib.maintainers; [
      griffi-gh
      { name = "nuko"; }
    ];
    platforms = lib.platforms.linux;
  };
}

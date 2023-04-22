{ 
  lib, 
  stdenv,
  fetchFromGitHub,
  cmake,
  # knotifications,
  # kxmlgui,
  # kglobalaccel,
  libsForQt5,
  pipewire,
  xdg-desktop-portal,
  pulseaudio,
  libpulseaudio,
  systemd
}:

stdenv.mkDerivation rec {
  pname = "discord-screenaudio";
  version = "1.8.1";

  src = fetchFromGitHub {
    owner = "maltejur";
    repo = "discord-screenaudio";
    rev = "7b6e8fc4735d62ff104f52daed842f5dcd3bf4d3";
    hash = "sha256-dCamrgtXhbtJvn8J1GVbY2mWLC3kZUGWbKcT44ei2MU=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    libsForQt5.qt5.wrapQtAppsHook
    cmake
    libsForQt5.qt5.qtbase
    libsForQt5.qt5.qtwebengine
    libsForQt5.knotifications
    libsForQt5.kxmlgui
    libsForQt5.kglobalaccel
  ];

  buildInputs = [
    pipewire
    pipewire.pulse
    xdg-desktop-portal
    pulseaudio
    libpulseaudio
    systemd
  ];

  libPath = lib.makeLibraryPath [
    pipewire
    pipewire.pulse
    xdg-desktop-portal
    pulseaudio
    libpulseaudio
    systemd
  ];

  NIX_CFLAGS_COMPILE = [
    "-I${pipewire.dev}/include/pipewire-0.3"
    "-I${pipewire.dev}/include/spa-0.2"
    "-Wno-pedantic"
  ];

  postFixup = ''
    wrapProgram $out/bin/discord-screenaudio \
      --suffix PATH : "${lib.makeBinPath [ pulseaudio ]}" \
      --prefix LD_LIBRARY_PATH : ${libPath}
  '';
}
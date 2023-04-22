{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, libsForQt5
, pipewire
, xdg-desktop-portal
}:

stdenv.mkDerivation rec {
  pname = "discord-screenaudio";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "maltejur";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-PPP/+7x0dcQHowB7hUZu85LK/G+ohrPeRB0vv6e3PBg=";
    fetchSubmodules = true;
  };

  cmakeFlags = [
    "-DPipeWire_INCLUDE_DIRS=${pipewire.dev}/include/pipewire-0.3"
    "-DSpa_INCLUDE_DIRS=${pipewire.dev}/include/spa-0.2"
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    libsForQt5.qt5.wrapQtAppsHook
  ];

  buildInputs = [
    libsForQt5.qt5.qtbase
    libsForQt5.qt5.qtwebengine
    libsForQt5.knotifications
    libsForQt5.kxmlgui
    libsForQt5.kglobalaccel
    pipewire
    pipewire.pulse
    xdg-desktop-portal
  ];
}

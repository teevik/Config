{ 
  lib,
  stdenv, 
  fetchFromGitLab, 
  pkg-config, 
  cmake, 
  extra-cmake-modules, 
  libsForQt5
}:
let
  xwvb-kpipewire = libsForQt5.kpipewire.overrideAttrs (_: _: { src = fetchFromGitLab {
      domain = "invent.kde.org";
      owner = "plasma";
      repo = "kpipewire";
      rev = "refs/merge-requests/27/head";
      hash = "sha256-KhmhlH7gaFGrvPaB3voQ57CKutnw5DlLOz7gy/3Mzms=";
    };
   });
in
stdenv.mkDerivation {
  name = "xwaylandvideobridge";
  version = "unstable";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "davidedmundson";
    repo = "xwaylandvideobridge";
    rev = "b876b5f3ee5cc810c99b08e8f0ebb29553e45e47";
    hash = "sha256-gfQkOIZegxdFQ9IV2Qp/lLRtfI5/g6bDD3XRBdLh4q0=";
  };

  nativeBuildInputs = [ libsForQt5.qt5.wrapQtAppsHook pkg-config cmake extra-cmake-modules ];
  buildInputs = [ xwvb-kpipewire libsForQt5.qt5.qtx11extras libsForQt5.ki18n libsForQt5.kwidgetsaddons libsForQt5.knotifications libsForQt5.kcoreaddons ];
}

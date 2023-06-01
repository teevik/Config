{ lib
, stdenv
, fetchFromGitLab
, libusb1
, hidapi
, pkg-config
, coreutils
, mbedtls_2
, symlinkJoin
, openrgb
, libsForQt5
}:

stdenv.mkDerivation {
  pname = "openrgb";
  version = "0.8";

  src = fetchFromGitLab {
    owner = "CalcProgrammer1";
    repo = "OpenRGB";
    rev = "a67cf011d585de78bcf24508ec819f9f44dc9439";
    hash = "sha256-X+cV2A9QT1CidTnq8vHE8o/FmoPw/3KZWVj9Jlx0LL8=";
  };

  nativeBuildInputs = [
    libsForQt5.qmake
    pkg-config
    libsForQt5.qt5.wrapQtAppsHook
  ];

  buildInputs = [
    libusb1
    hidapi
    mbedtls_2
    libsForQt5.qt5.qtbase
    libsForQt5.qt5.qttools
  ];

  postPatch = ''
    patchShebangs scripts/build-udev-rules.sh
    substituteInPlace scripts/build-udev-rules.sh \
      --replace /bin/chmod "${coreutils}/bin/chmod"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    HOME=$TMPDIR $out/bin/openrgb --help > /dev/null
  '';

  passthru.withPlugins = plugins:
    let
      pluginsDir = symlinkJoin {
        name = "openrgb-plugins";
        paths = plugins;
        # Remove all library version symlinks except one,
        # or they will result in duplicates in the UI.
        # We leave the one pointing to the actual library, usually the most
        # qualified one (eg. libOpenRGBHardwareSyncPlugin.so.1.0.0).
        postBuild = ''
          for f in $out/lib/*; do
            if [ "$(dirname $(readlink "$f"))" == "." ]; then
              rm "$f"
            fi
          done
        '';
      };
    in
    openrgb.overrideAttrs (old: {
      qmakeFlags = old.qmakeFlags or [ ] ++ [
        # Welcome to Escape Hell, we have backslashes
        ''DEFINES+=OPENRGB_EXTRA_PLUGIN_DIRECTORY=\\\""${lib.escape ["\\" "\"" " "] (toString pluginsDir)}/lib\\\""''
      ];
    });

  meta = with lib; {
    description = "Open source RGB lighting control";
    homepage = "https://gitlab.com/CalcProgrammer1/OpenRGB";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}

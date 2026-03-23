{
  pkgs,
}:
pkgs.stdenv.mkDerivation {
  pname = "peck";
  version = "0.1.2";

  src = pkgs.fetchurl {
    url = "https://github.com/codevogel/peck/releases/download/v0.1.2/peck";
    hash = "sha256-tZWGkyEIU2Hh5ofRxv8wiw1ezK46tzo8/RjmBfKsgqE=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/peck
    chmod +x $out/bin/peck

    wrapProgram $out/bin/peck \
      --run 'export PECK_SCREENSHOT_DIR="''${PECK_SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"' \
      --run 'export PECK_RECORDING_DIR="''${PECK_RECORDING_DIR:-$HOME/Videos/Recordings}"' \
      --prefix PATH : ${
        pkgs.lib.makeBinPath [
          pkgs.bash
          pkgs.grim
          pkgs.slurp
          pkgs.wf-recorder
          pkgs.ffmpeg
          pkgs.wl-clipboard
          pkgs.wayfreeze
          pkgs.libnotify
          pkgs.coreutils
          pkgs.procps
        ]
      }
  '';
}

{ inputs, pkgs }:
let
  inherit (pkgs) lib;
  official = inputs.noctalia-official-plugins;
  community = inputs.noctalia-community-plugins;
  # GSR 6.1.2 assumes FFmpeg 9 needs NVENC 13.1 and rejects NVIDIA 595
  # (NVENC 13.0) before encoding. FFmpeg 8 passes its compatibility check.
  gpuScreenRecorder = pkgs.gpu-screen-recorder.override { ffmpeg = pkgs.ffmpeg_8; };
  pluginFiles = pkgs.runCommand "noctalia-plugins" { } ''
    mkdir -p "$out/share/noctalia/plugins" "$out/bin"
    ${lib.concatMapStringsSep "\n"
      (name: ''
        cp -r ${official}/${name} "$out/share/noctalia/plugins/${name}"
      '')
      [
        "bongocat"
        "screen_recorder"
        "timer"
      ]
    }
    ${lib.concatMapStringsSep "\n"
      (name: ''
        cp -r ${community}/${name} "$out/share/noctalia/plugins/${name}"
      '')
      [
        "tailnet"
        "taildrop"
        "systemd"
        "ssh-launcher"
        "nix-search"
      ]
    }

    install -m755 ${community}/taildrop/bin/noctalia-taildrop "$out/bin/noctalia-taildrop"
    substituteInPlace "$out/bin/noctalia-taildrop" \
      --replace-fail '#!/usr/bin/env python3' '#!${pkgs.python3}/bin/python3' \
      --replace-fail '["noctalia",' '["${lib.getExe pkgs.noctalia}",'
  '';
  runtimeInputs = with pkgs; [
    coreutils
    evtest
    fzf
    glib # gio, used by Tailnet to open the Tailscale login URL
    gnutar
    gpuScreenRecorder
    nix-search-tv
    openssh
    procps
    systemd
    tailscale
    util-linux # setsid, used by the Nix Search background indexer
    xdg-user-dirs
    xdg-utils
  ];
in
pkgs.symlinkJoin {
  name = "noctalia-${pkgs.noctalia.version}-with-plugins";
  paths = [
    pkgs.noctalia
    pluginFiles
  ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/noctalia" --prefix PATH : ${lib.makeBinPath runtimeInputs}
  '';
  passthru = { inherit pluginFiles gpuScreenRecorder; };
  inherit (pkgs.noctalia) meta;
}

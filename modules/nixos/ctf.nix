{
  pkgs,
  lib,
  ...
}:
let
  # FHS environment for CTF tools and general development
  fhs = pkgs.buildFHSEnv (
    let
      base = pkgs.appimageTools.defaultFhsEnvArgs;
    in
    base
    // {
      name = "fhs";
      targetPkgs =
        pkgs:
        (base.targetPkgs pkgs)
        ++ (with pkgs; [
          (python3.withPackages (
            ps: with ps; [
              (matplotlib.override { enableQt = true; })
              tkinter
              pygobject3
              ipython
              pyqt6
              pip
            ]
          ))
          gtk3
          gobject-introspection
          librsvg
          file
          zlib
          dbus
          fontconfig
          freetype
          glib
          libGL
          libxkbcommon
          libx11
          wayland
          pkg-config
          ncurses
          lsb-release
          pciutils
          glibc_multi.bin
          xrandr
          which
          perl
          xdg-utils
          iana-etc
          python3
          xdg-user-dirs
          mesa
          sqlite
        ]);
      profile = ''
        export SHELL_ENV=fhs
        export FHS=1
      '';
      runScript = "nu";
      extraOutputsToInstall = [ "dev" ];
    }
  );
in
{
  environment.systemPackages = with pkgs; [
    hexyl
    katana
    ripgrep-all
    ghidra-bin
    pdfcrack
    stegsolve
    exiftool
    crunch
    hashcat-utils
    tesseract
    nth
    binwalk
    gdb
    nikto
    zap
    sqlmap
    sherlock
    seclists
    fhs

    (cutter.withPlugins (
      plugins: with plugins; [
        rz-ghidra
        jsdec
        sigdb
      ]
    ))
  ];

  environment.variables.SECLISTS = "${pkgs.seclists}";
}

{ pkgs, ... }:
let
  # FHS environment for CTF tools and general development.
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
              ipython
              pip
              pygobject3
              pyqt6
              tkinter
            ]
          ))
          dbus
          file
          fontconfig
          freetype
          glib
          glibc_multi.bin
          gobject-introspection
          gtk3
          iana-etc
          libGL
          librsvg
          libx11
          libxkbcommon
          lsb-release
          mesa
          ncurses
          pciutils
          perl
          pkg-config
          python3
          sqlite
          wayland
          which
          xdg-user-dirs
          xdg-utils
          xrandr
          zlib
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
    binwalk
    crunch
    exiftool
    fhs
    gdb
    ghidra-bin
    hashcat-utils
    hexyl
    katana
    nikto
    nth
    pdfcrack
    ripgrep-all
    seclists
    sherlock
    sqlmap
    stegsolve
    tesseract
    zap

    # TODO: Re-enable when upstream fixes Qt 6.11 / shiboken compatibility
    # https://github.com/rizinorg/cutter/issues/XXX
    # (cutter.withPlugins (
    #   plugins: with plugins; [
    #     rz-ghidra
    #     jsdec
    #     sigdb
    #   ]
    # ))

    (rizin.withPlugins (
      plugins: with plugins; [
        rz-ghidra
      ]
    ))
  ];

  environment.variables.SECLISTS = "${pkgs.seclists}";
}

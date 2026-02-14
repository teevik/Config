{ pkgs, ... }:
{
  # SecLists is the security tester's companion. It's a collection of multiple types of lists used during security assessments, collected in one place. List types include usernames, passwords, URLs, sensitive data patterns, fuzzing payloads, web shells, and many more.
  # https://github.com/danielmiessler/SecLists
  home.sessionVariables.SECLISTS = pkgs.seclists;

  home.packages = with pkgs; [
    hexyl

    # A next-generation crawling and spidering framework
    # https://github.com/projectdiscovery/katana
    katana

    # Powerful RSA cracker for CTFs. Supports RSA, X509, OPENSSH in PEM and DER formats
    # https://github.com/skyf0l/RsaCracker
    # teevik.rsa-cracker

    # rga: ripgrep, but also search in PDFs, E-Books, Office documents, zip, tar.gz, etc
    # https://github.com/phiresky/ripgrep-all
    ripgrep-all

    # A software reverse engineering (SRE) suite of tools developed by NSA's Research Directorate in support of the Cybersecurity mission
    # https://github.com/NationalSecurityAgency/ghidra
    ghidra-bin

    # Small command line driven tool for recovering passwords and content from PDF files
    # https://pdfcrack.sourceforge.net/
    pdfcrack

    # A steganographic image analyzer, solver and data extractor for challanges
    # http://www.caesum.com/handbook/stego.htm
    stegsolve

    # A tool to read, write and edit EXIF meta information
    exiftool

    # Crunch is a wordlist generator where you can specify a standard character set or a character set you specify
    # https://www.kali.org/tools/crunch/
    crunch

    # Fast password cracker
    # https://hashcat.net/hashcat/
    # hashcat
    # (hashcat.override { cudaSupport = true; })

    # Hashcat-utils are a set of small utilities that are useful in advanced password cracking
    # https://hashcat.net/wiki/doku.php?id=hashcat_utils
    hashcat-utils

    # Fast password cracker
    # https://github.com/openwall/john
    # john

    # OCR engine
    # https://github.com/tesseract-ocr/tesseract
    tesseract

    # The Modern Hash Identification System
    # https://github.com/HashPals/Name-That-Hash
    nth

    binwalk

    # TODO
    (cutter.withPlugins (
      plugins: with plugins; [
        rz-ghidra
        jsdec
        sigdb
      ]
    ))

    gdb

    # A simple package that helps you find meaningful lines of any given input. Especially useful in CTFs.
    # https://github.com/kamali-sina/meaningsearch
    # teevik.meaningsearch

    # Nikto web server scanner
    # https://github.com/sullo/nikto
    nikto

    # Zed Attack Proxy (ZAP)
    # https://github.com/zaproxy/zaproxy
    zap

    # Sql injections
    sqlmap

    sherlock

    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
      pkgs.buildFHSEnv (
        base
        // {
          name = "fhs";
          targetPkgs =
            pkgs:
            (
              # pkgs.buildFHSUserEnv provides only a minimal FHS environment,
              # lacking many basic packages needed by most software.
              # Therefore, we need to add them manually.
              #
              # pkgs.appimageTools provides basic packages required by most software.
              (base.targetPkgs pkgs)
              ++ (with pkgs; [
                (python3.withPackages (
                  ps: with ps; [
                    (matplotlib.override {
                      enableQt = true;
                    })
                    tkinter
                    pygobject3
                    ipython
                    pyqt6
                    pip

                  ]
                ))
                gtk3 # for Gtk3Agg matplotlib backend
                gobject-introspection # for Gtk3Agg matplotlib backend
                librsvg # for Gtk3Agg matplotlib backend
                file # for libmagic
                zlib # for numpy
                dbus # libdbus-1.so.3
                fontconfig # libfontconfig.so.1
                freetype # libfreetype.so.6
                glib # libglib-2.0.so.0
                libGL # libGL.so.1
                libxkbcommon # libxkbcommon.so.0
                libx11 # libX11.so.6
                wayland

                pkgs.glib
                pkgs.zlib
                pkgs.libGL
                pkgs.fontconfig
                pkgs.libx11
                pkgs.libxkbcommon
                pkgs.freetype
                pkgs.dbus

                pkg-config
                ncurses
                # Feel free to add more packages here if needed.

                # Needed for operating system detection until
                # https://github.com/ValveSoftware/steam-for-linux/issues/5909 is resolved
                lsb-release
                # Errors in output without those
                pciutils
                # run.sh wants ldconfig
                glibc_multi.bin
                # Games' dependencies
                xrandr
                which
                # Needed by gdialog, including in the steam-runtime
                perl
                # Open URLs
                xdg-utils
                iana-etc
                # Steam Play / Proton
                python3

                # It tries to execute xdg-user-dir and spams the log with command not founds
                xdg-user-dirs

                # electron based launchers need newer versions of these libraries than what runtime provides
                mesa
                sqlite
              ])
            );
          profile = # bash
            ''
              export SHELL_ENV=fhs
              export FHS=1
            '';
          runScript = "nu";
          extraOutputsToInstall = [ "dev" ];
        }
      )
    )

    # (
    #   pkgs.buildFHSUserEnv {
    #     name = "cuda";
    #     targetPkgs = pkgs: with pkgs; [
    #       git
    #       gitRepo
    #       gnupg
    #       autoconf
    #       curl
    #       procps
    #       gnumake
    #       util-linux
    #       m4
    #       gperf
    #       unzip
    #       cudatoolkit
    #       linuxPackages.nvidia_x11
    #       libGLU
    #       libGL
    #       xorg.libXi
    #       xorg.libXmu
    #       freeglut
    #       xorg.libXext
    #       xorg.libX11
    #       xorg.libXv
    #       xorg.libXrandr
    #       zlib
    #       ncurses5
    #       stdenv.cc
    #       binutils
    #     ];
    #     multiPkgs = pkgs: with pkgs; [ zlib ];
    #     runScript = "fish";
    #     profile = ''
    #       export SHELL_ENV=cuda
    #       export DT_RUNPATH=${lib.getLib pkgs.cudaPackages.cuda_cudart}/lib:$DT_RUNPATH
    #       export CUDA_PATH=${pkgs.cudatoolkit}
    #       # export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib
    #       export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
    #       export EXTRA_CCFLAGS="-I/usr/include"
    #     '';
    #   }
    # )
  ];
}

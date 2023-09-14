{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.ctf;
in
{
  options.teevik.suites.ctf = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable ctf suite
      '';
    };
  };

  config = mkIf cfg.enable {
    # SecLists is the security tester's companion. It's a collection of multiple types of lists used during security assessments, collected in one place. List types include usernames, passwords, URLs, sensitive data patterns, fuzzing payloads, web shells, and many more.
    # https://github.com/danielmiessler/SecLists
    home.sessionVariables.SECLISTS = pkgs.teevik.seclists;

    home.packages = with pkgs; [
      # A next-generation crawling and spidering framework
      # https://github.com/projectdiscovery/katana
      teevik.katana

      # Powerful RSA cracker for CTFs. Supports RSA, X509, OPENSSH in PEM and DER formats
      # https://github.com/skyf0l/RsaCracker
      teevik.rsa-cracker

      # rga: ripgrep, but also search in PDFs, E-Books, Office documents, zip, tar.gz, etc
      # https://github.com/phiresky/ripgrep-all
      # ripgrep-all

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
      hashcat

      # Hashcat-utils are a set of small utilities that are useful in advanced password cracking
      # https://hashcat.net/wiki/doku.php?id=hashcat_utils
      hashcat-utils

      # Fast password cracker
      # https://github.com/openwall/john
      john

      # OCR engine
      # https://github.com/tesseract-ocr/tesseract
      tesseract

      # The Modern Hash Identification System
      # https://github.com/HashPals/Name-That-Hash
      nth

      binwalk

      (cutter.withPlugins (plugins: with plugins;[ rz-ghidra jsdec ]))

      gdb
    ];
  };
}

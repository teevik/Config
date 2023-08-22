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

      # Broken
      # teevik.ripgrep-all

      # A software reverse engineering (SRE) suite of tools developed by NSA's Research Directorate in support of the Cybersecurity mission
      # https://github.com/NationalSecurityAgency/ghidra
      ghidra-bin

      # Small command line driven tool for recovering passwords and content from PDF files
      # https://pdfcrack.sourceforge.net/
      pdfcrack

      # A steganographic image analyzer, solver and data extractor for challanges
      # http://www.caesum.com/handbook/stego.htm
      stegsolve

      exiftool
    ];
  };
}

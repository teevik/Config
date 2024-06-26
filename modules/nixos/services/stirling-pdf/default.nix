{ config
, lib
, options
, pkgs
, ...
}:

let
  inherit (lib)
    getExe
    literalExpression
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    optional
    ;

  inherit (lib.types)
    attrsOf
    either
    nullOr
    path
    port
    str
    ;

  cfg = config.teevik.services.stirling-pdf;
in

{
  meta.maintainers = with lib.maintainers; [ thubrecht ];

  options.teevik.services.stirling-pdf = {
    enable = mkEnableOption "Stirling-PDF, a web application for manipulating PDF files";

    package = mkPackageOption pkgs "stirling-pdf" { };

    port = mkOption {
      type = port;
      default = 8080;
      description = ''
        Port that Stirling-PDF will listen on.
      '';
    };

    environment = mkOption {
      type = attrsOf (nullOr (either str path));
      defaultText = ''
        {
          SERVER_PORT = cfg.port;
        }
      '';
      description = ''
        Settings for the stirling-pdf app.
      '';
    };

    environmentFile = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        File containing additional environment variables to pass to Stirling PDF.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.stirling-pdf = {
      inherit (cfg) environment;

      path = with pkgs; [
        calibre
        ghostscript_headless
        libreoffice
        ocrmypdf
        opencv
        pngquant
        tesseract
        unoconv
        unpaper

        python3.pkgs.weasyprint
      ];

      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        BindReadOnlyPaths = [ "${pkgs.tesseract}/share/tessdata:/usr/share/tessdata" ];
        CacheDirectory = "stirling-pdf";
        Environment = [ "HOME=%S/stirling-pdf" ];
        EnvironmentFile = optional (cfg.environmentFile != null) cfg.environmentFile;
        ExecStart = getExe cfg.package;
        RuntimeDirectory = "stirling-pdf";
        StateDirectory = "stirling-pdf";
        SuccessExitStatus = 143;
        User = "stirling-pdf";
        WorkingDirectory = "/var/lib/stirling-pdf";

        # Hardening
        CapabilityBoundingSet = "";
        DynamicUser = true;
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "~@cpu-emulation @debug @keyring @mount @obsolete @privileged @resources @clock @setuid @chown"
        ];
        UMask = "0077";
      };
    };

    teevik.services.stirling-pdf.environment = {
      # Default values
      SERVER_PORT = builtins.toString cfg.port;
      INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "true";
    };
  };
}

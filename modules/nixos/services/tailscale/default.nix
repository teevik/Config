{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.tailscale;
in
{
  options.teevik.services.tailscale = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tailscale
      '';
    };

    exitNode = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The exit node to use
      '';
    };

    funnel = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        The funnel port to use
      '';
    };

    proxies = mkOption {
      default = { };

      type = with types;
        attrsOf (submodule {
          options = {
            enable = (mkEnableOption "tailscale-proxy") // { default = true; };

            hostname = mkOption {
              type = types.str;
              description = "Hostname to use, presented via MagicDNS";
            };

            port = mkOption {
              type = types.port;
              description = "Port to proxy onto the tailscale network";
            };
          };
        });

      description = lib.mdDoc ''
        Multiple tailscale-proxies
      '';
    };
  };

  config = mkIf cfg.enable
    {
      services.tailscale = {
        enable = true;

        authKeyFile = config.age.secrets.tailscale.path;
        extraUpFlags = [ "--operator=teevik" ];

        useRoutingFeatures = mkIf (cfg.exitNode != null) "both";
      };

      # Exit node
      systemd.services.tailscale-exit-node = mkIf (cfg.exitNode != null) {
        after = [ "tailscaled-autoconnect.service" ];
        wants = [ "tailscaled-autoconnect.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${lib.getExe pkgs.tailscale} up --operator=teevik --exit-node=${cfg.exitNode} 
        '';
      };

      # Funnel
      systemd.services.tailscale-funnel = mkIf (cfg.funnel != null) {
        after = [ "tailscaled-autoconnect.service" ];
        wants = [ "tailscaled-autoconnect.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
        };
        script = ''
          ${lib.getExe pkgs.tailscale} funnel ${toString cfg.funnel} 
        '';
      };
    };
}

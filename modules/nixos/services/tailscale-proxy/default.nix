{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.tailscale-proxy;

  tailscale = pkgs.tailscale.overrideAttrs (finalAttrs: previousAttrs: {
    subPackages = previousAttrs.subPackages ++ [ "cmd/proxy-to-grafana" ];
  });
  proxyToGrafana = "${tailscale}/bin/proxy-to-grafana";

  proxyUsername = "tailscale-proxy";
  baseDataDir = "/var/lib/tailscale-proxy";
in
{
  options.teevik.services.tailscale-proxy = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tailscale-proxy
      '';
    };

    proxies = mkOption {
      default = { };

      type = with types;
        attrsOf (submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "tailscale-proxy";
            };

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

  config = mkIf cfg.enable {
    users.users.tailscale-proxy = {
      home = baseDataDir;
      createHome = true;
      group = proxyUsername;
      isSystemUser = false;
      isNormalUser = true;
      description = proxyUsername;
    };

    users.groups.tailscale-proxy = { };

    systemd.services = lib.flip lib.mapAttrs' cfg.proxies (
      subSvcName: svcConfig:
        let
          svcName = "${proxyUsername}-${subSvcName}";
          dataDir = "${baseDataDir}/${subSvcName}";
        in
        lib.nameValuePair svcName
          {
            inherit (svcConfig) enable;
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            restartTriggers = [ tailscale ];
            script = ''
              mkdir -p ${dataDir}
              export TS_AUTHKEY=`cat ${config.age.secrets.tailscale.path}`
              ${proxyToGrafana} \
                --hostname=${svcConfig.hostname} \
                --backend-addr=localhost:${toString svcConfig.port} \
                --state-dir=${dataDir} \
                --use-https=false
            '';

            serviceConfig = {
              User = proxyUsername;
              Group = proxyUsername;
              Restart = "always";
              RestartSec = "15";
              WorkingDirectory = baseDataDir;
            };
          }
    );
  };
}

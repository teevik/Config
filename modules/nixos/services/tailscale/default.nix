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
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscale.path;
      extraUpFlags = [ "--operator=teevik" ];

      useRoutingFeatures = mkIf (cfg.exitNode != null) "both";
    };

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

    systemd.services.tailscale-funnel = mkIf (cfg.funnel != null) {
      after = [ "tailscaled-autoconnect.service" ];
      wants = [ "tailscaled-autoconnect.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        ${lib.getExe pkgs.tailscale} funnel ${cfg.funnel} 
      '';
    };

  };
}

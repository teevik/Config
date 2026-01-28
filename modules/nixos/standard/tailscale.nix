{ config, lib, ... }:
{
  services.tailscale = {
    enable = true;

    authKeyFile = config.sops.secrets.tailscale.path;
    extraUpFlags = [ "--operator=teevik" ];
  };

  # Move tailscaled-autoconnect to network-online.target instead of multi-user.target
  # This prevents it from blocking the boot chain while still starting when network is ready
  systemd.services.tailscaled-autoconnect = {
    after = lib.mkForce [
      "network-online.target"
      "tailscaled.service"
    ];
    wantedBy = lib.mkForce [ "network-online.target" ];
    wants = lib.mkForce [
      "network-online.target"
      "tailscaled.service"
    ];
  };

  # https://github.com/tailscale/tailscale/issues/4254#issuecomment-1684936951
  services.resolved.enable = true;

  networking.firewall = {
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];
  };
}

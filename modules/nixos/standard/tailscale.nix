{ config, ... }:
{
  services.tailscale = {
    enable = true;

    authKeyFile = config.age.secrets.tailscale.path;
    extraUpFlags = [ "--operator=teevik" ];
  };

  # https://github.com/tailscale/tailscale/issues/4254#issuecomment-1684936951
  services.resolved.enable = true;

  networking.firewall = {
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];
  };
}

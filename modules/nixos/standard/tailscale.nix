{ config, ... }:
{
  services.tailscale = {
    enable = true;

    authKeyFile = config.age.secrets.tailscale.path;
    extraUpFlags = [ "--operator=teevik" ];
  };

  networking.firewall = {
    # Always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];
  };
}

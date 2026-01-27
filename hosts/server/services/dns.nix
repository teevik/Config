# DNS (dnsmasq for Tailscale)
{ config, ... }:
let
  inherit (config.lab) domain;

  # Server's Tailscale IP
  tailscaleIP = "100.65.233.122";
in
{
  services.dnsmasq = {
    enable = true;
    settings = {
      # Resolve *.lab.teevik.no to this server's Tailscale IP
      address = "/${domain}/${tailscaleIP}";

      # Forward other DNS queries upstream
      server = [
        "1.1.1.1"
        "8.8.8.8"
      ];

      # Only listen on Tailscale interface
      interface = "tailscale0";
      bind-interfaces = true;

      # Don't read /etc/resolv.conf
      no-resolv = true;
    };
  };
}

{
  config,
  ...
}:
{
  services.harmonia = {
    enable = true;
    signKeyPaths = [ config.sops.secrets.harmonia-signing-key.path ];
    settings.bind = "[::]:5000";
  };

  sops.secrets.harmonia-signing-key = { };

  # Only allow access via Tailscale
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5000 ];
}

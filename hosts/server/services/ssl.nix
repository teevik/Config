# SSL Certificates (Let's Encrypt via Cloudflare DNS challenge)
# Automatically collects subdomains from lab.services
{ lib, config, ... }:
let
  inherit (config.lab) domain services;

  # Collect all subdomains from registered services
  subdomains = lib.filter (s: s != null) (lib.mapAttrsToList (_: svc: svc.subdomain) services);

  # Convert to full domain names
  extraDomains = map (sub: "${sub}.${domain}") subdomains;
in
{
  shb.certs.certs.letsencrypt.${domain} = {
    inherit domain extraDomains;
    dnsProvider = "cloudflare";
    dnsResolver = "1.1.1.1:53";
    credentialsFile = config.sops.secrets."cloudflare/api_token".path;
    adminEmail = "teemuvikoren1@gmail.com";
    group = "nginx";
    reloadServices = [ "nginx.service" ];
  };
}

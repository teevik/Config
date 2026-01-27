# SSL Certificates (Let's Encrypt via Cloudflare DNS challenge)
# Wildcard certificate covers all subdomains
{ config, ... }:
let
  inherit (config.lab) domain;
in
{
  shb.certs.certs.letsencrypt.${domain} = {
    inherit domain;
    # Wildcard covers all *.lab.teevik.no subdomains
    extraDomains = [ "*.${domain}" ];
    dnsProvider = "cloudflare";
    dnsResolver = "1.1.1.1:53";
    credentialsFile = config.sops.secrets."cloudflare/api_token".path;
    adminEmail = "teemuvikoren1@gmail.com";
    group = "nginx";
    reloadServices = [ "nginx.service" ];
  };
}

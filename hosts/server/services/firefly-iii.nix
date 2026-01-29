# Firefly III (Personal Finance Manager)
{ config, ... }:
let
  inherit (config.lab) domain;
in
{
  # Register Firefly III in service registry
  lab.services.firefly-iii = {
    name = "Firefly III";
    subdomain = "firefly";
    icon = "firefly-iii";
    description = "Personal Finance";
    category = "Services";
    ssoEnabled = true;
    ldapGroups = {
      user = "firefly-iii_user";
      admin = "firefly-iii_admin";
    };
  };

  # Firefly III configuration
  shb.firefly-iii = {
    enable = true;
    inherit domain;
    subdomain = "firefly";
    siteOwnerEmail = "teemuvikoren1@gmail.com";

    ssl = config.shb.certs.certs.letsencrypt.${domain};

    # Secrets
    appKey.result = config.shb.sops.secret."firefly-iii/appKey".result;
    dbPassword.result = config.shb.sops.secret."firefly-iii/dbPassword".result;

    # SSO integration with Authelia
    sso = {
      enable = true;
      authEndpoint = "https://${config.shb.authelia.subdomain}.${config.shb.authelia.domain}";
      secret.result = config.shb.sops.secret."firefly-iii/oidc_secret".result;
      secretForAuthelia.result = config.shb.sops.secret."firefly-iii/oidc_secret_authelia".result;
    };

    # Data importer
    importer = {
      enable = true;
      firefly-iii-accessToken.result = config.shb.sops.secret."firefly-iii/importerAccessToken".result;
    };
  };

  # Wire up secrets via shb.sops
  shb.sops.secret."firefly-iii/appKey".request = config.shb.firefly-iii.appKey.request;
  shb.sops.secret."firefly-iii/dbPassword".request = config.shb.firefly-iii.dbPassword.request;
  shb.sops.secret."firefly-iii/oidc_secret".request = config.shb.firefly-iii.sso.secret.request;
  shb.sops.secret."firefly-iii/oidc_secret_authelia" = {
    request = config.shb.firefly-iii.sso.secretForAuthelia.request;
    settings = {
      key = "firefly-iii/oidc_secret";
      sopsFile = ../secrets.yaml;
    };
  };
  shb.sops.secret."firefly-iii/importerAccessToken".request =
    config.shb.firefly-iii.importer.firefly-iii-accessToken.request;
}

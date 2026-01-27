# Authelia (SSO/Authentication)
{ config, ... }:
let
  inherit (config.lab) domain;
in
{
  # Register Authelia in service registry
  lab.services.authelia = {
    name = "Authelia";
    subdomain = "auth";
    icon = "https://raw.githubusercontent.com/Jas-SinghFSU/homepage-catppuccin/main/catppuccin_icons/authelia.png";
    internalPort = 9091;
    description = "Single Sign-On";
    category = "Services";
    ssoEnabled = false; # Authelia is the SSO provider itself
  };

  # Authelia configuration
  shb.authelia = {
    enable = true;
    subdomain = "auth";
    inherit domain;
    ssl = config.shb.certs.certs.letsencrypt.${domain};

    ldapHostname = "127.0.0.1";
    ldapPort = config.shb.lldap.ldapPort;
    dcdomain = config.shb.lldap.dcdomain;

    # Secrets via shb.sops
    secrets = {
      jwtSecret.result = config.shb.sops.secret."authelia/jwt_secret".result;
      ldapAdminPassword.result = config.shb.sops.secret."authelia/ldap_admin_password".result;
      sessionSecret.result = config.shb.sops.secret."authelia/session_secret".result;
      storageEncryptionKey.result = config.shb.sops.secret."authelia/storage_encryption_key".result;
      identityProvidersOIDCHMACSecret.result = config.shb.sops.secret."authelia/hmac_secret".result;
      identityProvidersOIDCIssuerPrivateKey.result = config.shb.sops.secret."authelia/private_key".result;
    };
  };

  # Wire up Authelia secrets via shb.sops
  shb.sops.secret."authelia/jwt_secret".request = config.shb.authelia.secrets.jwtSecret.request;
  shb.sops.secret."authelia/ldap_admin_password" = {
    request = config.shb.authelia.secrets.ldapAdminPassword.request;
    settings.key = "lldap/user_password"; # Reuse LLDAP admin password
  };
  shb.sops.secret."authelia/session_secret".request =
    config.shb.authelia.secrets.sessionSecret.request;
  shb.sops.secret."authelia/storage_encryption_key".request =
    config.shb.authelia.secrets.storageEncryptionKey.request;
  shb.sops.secret."authelia/hmac_secret".request =
    config.shb.authelia.secrets.identityProvidersOIDCHMACSecret.request;
  shb.sops.secret."authelia/private_key".request =
    config.shb.authelia.secrets.identityProvidersOIDCIssuerPrivateKey.request;
}

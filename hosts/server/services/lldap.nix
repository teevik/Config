# LLDAP (Lightweight LDAP for User Management)
# Automatically creates LDAP groups from lab.services.*.ldapGroups
{ lib, config, ... }:
let
  inherit (config.lab) domain services;

  # Collect all LDAP groups from registered services
  allGroups = lib.unique (
    lib.flatten (
      lib.mapAttrsToList (
        _: svc:
        lib.optionals (svc.ldapGroups != null) (
          lib.optional (svc.ldapGroups.user != null) svc.ldapGroups.user
          ++ lib.optional (svc.ldapGroups.admin != null) svc.ldapGroups.admin
        )
      ) services
    )
  );

  # Convert to ensureGroups format
  ensureGroups = lib.genAttrs allGroups (_: { });
in
{
  # Register LLDAP in service registry
  lab.services.lldap = {
    name = "LLDAP";
    subdomain = "ldap";
    icon = "lldap-dark";
    internalPort = 17170;
    description = "User Management";
    category = "Services";
    ssoEnabled = false;
  };

  # LLDAP configuration
  shb.lldap = {
    enable = true;
    subdomain = "ldap";
    inherit domain;
    dcdomain = "dc=lab,dc=teevik,dc=no";

    ssl = config.shb.certs.certs.letsencrypt.${domain};

    # Secrets via shb.sops
    jwtSecret.result = config.shb.sops.secret."lldap/jwt_secret".result;
    ldapUserPassword.result = config.shb.sops.secret."lldap/user_password".result;

    # Restrict LLDAP UI access to Tailscale network
    restrictAccessIPRange = "100.64.0.0/10";

    # Auto-generated groups from services + any additional manual groups
    inherit ensureGroups;
  };

  # Wire up LLDAP secrets via shb.sops
  shb.sops.secret."lldap/jwt_secret".request = config.shb.lldap.jwtSecret.request;
  shb.sops.secret."lldap/user_password".request = config.shb.lldap.ldapUserPassword.request;
}

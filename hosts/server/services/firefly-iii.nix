# Firefly III (Personal Finance Manager)
{ config, pkgs, ... }:
let
  inherit (config.lab) domain;
in
{
  # Override data importer to use main branch for Enable Banking support
  services.firefly-iii-data-importer.package =
    let
      newSrc = pkgs.fetchFromGitHub {
        owner = "firefly-iii";
        repo = "data-importer";
        rev = "aa30ddf424de89474fe759530e7b993241fc2232"; # Enable Banking support
        hash = "sha256-1gWw3FTwUU8udgSK6f0TahSsx6y+MKJs6UyvEoEKpyw=";
      };
      newVersion = "2.1.0-dev";
    in
    (pkgs.firefly-iii-data-importer.override { }).overrideAttrs (old: {
      version = newVersion;
      src = newSrc;
      vendorHash = "sha256-F48TjbSXNeq339xFrc/Yp/p/3pPr9MkNtwfNH7KA0sM=";
      npmDeps = pkgs.fetchNpmDeps {
        src = newSrc;
        name = "firefly-iii-data-importer-npm-deps";
        hash = "sha256-VMLnOWR+UvhkCYNxUSZDi7Q98+kgPdJ6n9mej3Xm5O0=";
      };
      composerRepository = pkgs.php84.mkComposerRepository {
        pname = "firefly-iii-data-importer";
        version = newVersion;
        src = newSrc;
        vendorHash = "sha256-F48TjbSXNeq339xFrc/Yp/p/3pPr9MkNtwfNH7KA0sM=";
        composerNoDev = true;
        composerNoPlugins = true;
        composerNoScripts = true;
        composerStrictValidation = false;
      };
    });
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

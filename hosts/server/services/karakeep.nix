# Karakeep (AI-powered Bookmarking)
{ config, ... }:
let
  inherit (config.lab) domain;
in
{
  # Register Karakeep in service registry
  lab.services.karakeep = {
    name = "Karakeep";
    subdomain = "keep";
    icon = "karakeep";
    internalPort = 13000;
    description = "AI Bookmarking";
    category = "Services";
    ssoEnabled = true;
    ldapGroups = {
      user = "karakeep_user";
    };
  };

  # Karakeep configuration
  shb.karakeep = {
    enable = true;
    inherit domain;
    subdomain = "keep";
    port = 13000; # Default 3000 is used by Grafana

    ssl = config.shb.certs.certs.letsencrypt.${domain};

    # Secrets
    nextauthSecret.result = config.shb.sops.secret."karakeep/nextauth_secret".result;
    meilisearchMasterKey.result = config.shb.sops.secret."karakeep/meilisearch_key".result;

    # SSO integration with Authelia
    sso = {
      enable = true;
      authEndpoint = "https://${config.shb.authelia.subdomain}.${config.shb.authelia.domain}";

      sharedSecret.result = config.shb.sops.secret."karakeep/oidc_secret".result;
      sharedSecretForAuthelia.result = config.shb.sops.secret."karakeep/oidc_secret_authelia".result;
    };

    # Use LiteLLM proxy (shared with Open-WebUI) for AI features
    environment = {
      OPENAI_BASE_URL = "http://127.0.0.1:4000/v1";
      OPENAI_API_KEY = "dummy";
      INFERENCE_TEXT_MODEL = "Claude Haiku 3.5";
      INFERENCE_IMAGE_MODEL = "Claude Haiku 4.5 Vision";
      INFERENCE_ENABLE_AUTO_SUMMARIZATION = "true";
    };
  };

  # Wire up secrets via shb.sops
  shb.sops.secret."karakeep/nextauth_secret".request = config.shb.karakeep.nextauthSecret.request;
  shb.sops.secret."karakeep/meilisearch_key".request =
    config.shb.karakeep.meilisearchMasterKey.request;
  shb.sops.secret."karakeep/oidc_secret".request = config.shb.karakeep.sso.sharedSecret.request;
  shb.sops.secret."karakeep/oidc_secret_authelia" = {
    request = config.shb.karakeep.sso.sharedSecretForAuthelia.request;
    settings.key = "karakeep/oidc_secret";
  };
}

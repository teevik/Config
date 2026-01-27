# Open-WebUI (AI Chat Interface)
{ config, ... }:
let
  inherit (config.lab) domain;
in
{
  # Register Open-WebUI in service registry
  lab.services.open-webui = {
    name = "Open WebUI";
    subdomain = "chat";
    icon = "https://raw.githubusercontent.com/Jas-SinghFSU/homepage-catppuccin/main/catppuccin_icons/open-webui.png";
    internalPort = 12444;
    description = "AI Chat Interface";
    category = "Services";
    ssoEnabled = true;
    ldapGroups = {
      user = "open-webui_user";
      admin = "open-webui_admin";
    };
  };

  # Open-WebUI configuration
  shb.open-webui = {
    enable = true;
    inherit domain;
    subdomain = "chat";

    ssl = config.shb.certs.certs.letsencrypt.${domain};

    sso = {
      enable = true;
      authEndpoint = "https://${config.shb.authelia.subdomain}.${config.shb.authelia.domain}";

      sharedSecret.result = config.shb.sops.secret."open-webui/oidc_secret".result;
      sharedSecretForAuthelia.result = config.shb.sops.secret."open-webui/oidc_secret_authelia".result;
    };

    # Connect to LiteLLM proxy
    environment = {
      OPENAI_API_BASE_URL = "http://127.0.0.1:4000/v1";
      OPENAI_API_KEY = "dummy";
    };
  };

  # Wire up Open-WebUI secrets via shb.sops
  shb.sops.secret."open-webui/oidc_secret".request = config.shb.open-webui.sso.sharedSecret.request;
  shb.sops.secret."open-webui/oidc_secret_authelia" = {
    request = config.shb.open-webui.sso.sharedSecretForAuthelia.request;
    settings.key = "open-webui/oidc_secret"; # Same secret, different permissions
  };
}

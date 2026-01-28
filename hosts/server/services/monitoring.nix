# Monitoring (Grafana, Prometheus, Loki)
{ pkgs, config, ... }:
let
  inherit (config.lab) domain;
in
{
  # Register Grafana in service registry
  lab.services.grafana = {
    name = "Grafana";
    subdomain = "grafana";
    icon = "https://raw.githubusercontent.com/Jas-SinghFSU/homepage-catppuccin/main/catppuccin_icons/grafana.png";
    healthCheckUrl = "http://127.0.0.1:3000/api/health";
    description = "Metrics & Dashboards";
    category = "Monitoring";
    ssoEnabled = true;
    ldapGroups = {
      user = "monitoring_user";
      admin = "monitoring_admin";
    };
  };

  # Monitoring configuration
  shb.monitoring = {
    enable = true;
    subdomain = "grafana";
    inherit domain;

    ssl = config.shb.certs.certs.letsencrypt.${domain};

    # Admin password for initial setup
    adminPassword.result = config.shb.sops.secret."monitoring/admin_password".result;
    secretKey.result = config.shb.sops.secret."monitoring/secret_key".result;

    # SSO integration with Authelia
    sso = {
      enable = true;
      authEndpoint = "https://${config.shb.authelia.subdomain}.${config.shb.authelia.domain}";

      sharedSecret.result = config.shb.sops.secret."monitoring/oidc_secret".result;
      sharedSecretForAuthelia.result = config.shb.sops.secret."monitoring/oidc_secret_authelia".result;
    };
  };

  # Wire up Monitoring secrets via shb.sops
  shb.sops.secret."monitoring/admin_password".request = config.shb.monitoring.adminPassword.request;
  shb.sops.secret."monitoring/secret_key".request = config.shb.monitoring.secretKey.request;
  shb.sops.secret."monitoring/oidc_secret".request = config.shb.monitoring.sso.sharedSecret.request;
  shb.sops.secret."monitoring/oidc_secret_authelia" = {
    request = config.shb.monitoring.sso.sharedSecretForAuthelia.request;
    settings = {
      key = "monitoring/oidc_secret"; # Same secret, different permissions
      sopsFile = ../secrets.yaml;
    };
  };

  # Grafana Home Dashboard (Node Exporter Full)
  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "home";
      orgId = 1;
      folder = "";
      type = "file";
      disableDeletion = true;
      options.path = "/etc/grafana-dashboards";
    }
  ];

  services.grafana.settings.dashboards.default_home_dashboard_path =
    "/etc/grafana-dashboards/node-exporter-full.json";

  environment.etc."grafana-dashboards/node-exporter-full.json".source =
    ../dashboards/node-exporter-full.json;
}

# Homepage Dashboard
# Automatically generates service entries from lab.services
{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (config.lab) domain services;

  # Group services by category
  byCategory = lib.groupBy (svc: svc.category) (lib.attrValues services);

  # Sort categories with "Services" first, then "Monitoring", then alphabetically
  categoryOrder =
    cat:
    if cat == "Services" then
      "0-${cat}"
    else if cat == "Monitoring" then
      "1-${cat}"
    else
      "2-${cat}";

  sortedCategories = lib.sort (a: b: categoryOrder a < categoryOrder b) (lib.attrNames byCategory);

  # Convert a service to Homepage format
  serviceToHomepage = svc: {
    ${svc.name} = {
      inherit (svc) icon description;
      href = svc.url;
    }
    // lib.optionalAttrs (svc.healthCheckUrl != null) {
      siteMonitor = svc.healthCheckUrl;
    };
  };

  # Generate homepage services structure
  homepageServices = map (category: {
    ${category} = map serviceToHomepage byCategory.${category};
  }) sortedCategories;

  # Generate layout config from categories
  layoutConfig = lib.listToAttrs (
    map (category: {
      name = category;
      value = {
        style = "row";
        columns = if category == "Monitoring" then 1 else 3;
      };
    }) sortedCategories
  );
in
{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = domain;

    settings = {
      title = domain;
      favicon = "https://cdn-icons-png.flaticon.com/512/1946/1946488.png";
      headerStyle = "clean";
      color = "gray"; # Required for Catppuccin theme
      statusStyle = "dot";
      layout = layoutConfig;
    };

    # Catppuccin theme
    customCSS = builtins.readFile (
      pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/Jas-SinghFSU/homepage-catppuccin/main/custom.css";
        hash = "sha256-82P0x/QV3WqJssw17b3mP6Brg5dkiKbJWCOs/m8y5B0=";
      }
    );

    widgets = [
      {
        datetime = {
          text_size = "xl";
          format = {
            dateStyle = "long";
            timeStyle = "short";
            hourCycle = "h23";
          };
        };
      }
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
    ];

    services = homepageServices;
  };

  # Nginx reverse proxy for Homepage Dashboard with SSL
  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    sslCertificate = config.shb.certs.certs.letsencrypt.${domain}.paths.cert;
    sslCertificateKey = config.shb.certs.certs.letsencrypt.${domain}.paths.key;

    # Restrict to Tailscale network
    extraConfig = ''
      allow 100.64.0.0/10;
      deny all;
    '';

    locations."/" = {
      proxyPass = "http://127.0.0.1:8082";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}

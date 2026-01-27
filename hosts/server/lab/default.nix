# Lab infrastructure and service registry
# Defines lab.* options and imports SSL, DNS, and services
{ lib, config, ... }:
let
  cfg = config.lab;

  ldapGroupsOpts = {
    options = {
      user = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "LDAP group for regular users";
      };
      admin = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "LDAP group for admins";
      };
    };
  };

  serviceOpts =
    { name, config, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Display name for the service";
        };

        subdomain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Subdomain for the service (used to auto-derive url)";
        };

        icon = lib.mkOption {
          type = lib.types.str;
          description = "Icon URL or dashboard-icons name";
        };

        url = lib.mkOption {
          type = lib.types.str;
          default = if config.subdomain != null then "https://${config.subdomain}.${cfg.domain}" else "";
          description = "Public URL for the service (auto-derived from subdomain if not set)";
        };

        internalPort = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
          description = "Internal port for the service (used to auto-derive healthCheckUrl)";
        };

        healthCheckUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default =
            if config.internalPort != null then "http://127.0.0.1:${toString config.internalPort}" else null;
          description = "Internal URL for health checks (auto-derived from internalPort if not set)";
        };

        description = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Short description of the service";
        };

        category = lib.mkOption {
          type = lib.types.str;
          default = "Services";
          description = "Dashboard category/group for organizing services";
        };

        ssoEnabled = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this service uses SSO via Authelia";
        };

        ldapGroups = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule ldapGroupsOpts);
          default = null;
          description = "LDAP groups for access control";
        };
      };
    };
in
{
  imports = [
    ./ssl.nix
    ./dns.nix
    ../services
  ];

  options.lab = {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Base domain for all services";
    };

    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule serviceOpts);
      default = { };
      description = "Service registry for dashboard and automatic configuration";
    };
  };

  config.lab.domain = "lab.teevik.no";
}

{
  flake,
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  domain = "lab.teevik.no";
in
{
  imports = [
    ./hardware.nix

    inputs.disko.nixosModules.disko
    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
  ];

  system.autoUpgrade = {
    enable = true;
    flake = "github:teevik/Config";
    allowReboot = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "server";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  # Disable the lid switch
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  # Acceleration
  boot.kernelParams = [
    "i915.enable_guc=2"
  ];

  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      libvdpau-va-gl
      intel-vaapi-driver
      libva-vdpau-driver
    ];
  };

  # SOPS Secrets Configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/home/teevik/.config/sops/age/keys.txt";

    secrets = {
      # Cloudflare DNS credentials for Let's Encrypt (CF_DNS_API_TOKEN=xxx)
      "cloudflare/api_token" = { };

      # LiteLLM environment (OPENCODE_ZEN_API_KEY=xxx)
      "litellm/env" = { };
    };
  };

  # SSL Certificates (Let's Encrypt)
  shb.certs.certs.letsencrypt.${domain} = {
    inherit domain;
    extraDomains = [
      "ldap.${domain}"
      "auth.${domain}"
      "chat.${domain}"
    ];
    dnsProvider = "cloudflare";
    dnsResolver = "1.1.1.1:53";
    credentialsFile = config.sops.secrets."cloudflare/api_token".path;
    adminEmail = "teemuvikoren1@gmail.com";
    group = "nginx";
    reloadServices = [ "nginx.service" ];
  };

  # LLDAP (User Management)
  shb.lldap = {
    enable = true;
    subdomain = "ldap";
    inherit domain;
    dcdomain = "dc=lab,dc=teevik,dc=no";

    ssl = config.shb.certs.certs.letsencrypt.${domain};

    # Use shb.sops for contract-based secrets
    jwtSecret.result = config.shb.sops.secret."lldap/jwt_secret".result;
    ldapUserPassword.result = config.shb.sops.secret."lldap/user_password".result;

    # Restrict LLDAP UI access to Tailscale network
    restrictAccessIPRange = "100.64.0.0/10";

    # Define groups for services
    ensureGroups = {
      open-webui_user = { };
      open-webui_admin = { };
    };
  };

  # Wire up LLDAP secrets via shb.sops
  shb.sops.secret."lldap/jwt_secret".request = config.shb.lldap.jwtSecret.request;
  shb.sops.secret."lldap/user_password".request = config.shb.lldap.ldapUserPassword.request;

  # Authelia (SSO/Authentication)
  shb.authelia = {
    enable = true;
    subdomain = "auth";
    inherit domain;
    ssl = config.shb.certs.certs.letsencrypt.${domain};

    ldapHostname = "127.0.0.1";
    ldapPort = config.shb.lldap.ldapPort;
    dcdomain = config.shb.lldap.dcdomain;

    # Use filesystem for notifications (no SMTP setup needed initially)
    smtp = "/var/lib/authelia-notifications";

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

  # Open-WebUI with SSO
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
      OPENAI_API_KEY = "dummy"; # LiteLLM doesn't require auth by default
    };
  };

  # Wire up Open-WebUI secrets via shb.sops
  shb.sops.secret."open-webui/oidc_secret".request = config.shb.open-webui.sso.sharedSecret.request;
  shb.sops.secret."open-webui/oidc_secret_authelia" = {
    request = config.shb.open-webui.sso.sharedSecretForAuthelia.request;
    settings.key = "open-webui/oidc_secret"; # Same secret, different permissions
  };

  # DNS (dnsmasq for Tailscale)
  services.dnsmasq = {
    enable = true;
    settings = {
      # Resolve *.lab.teevik.no to this server's Tailscale IP
      address = "/lab.teevik.no/100.65.233.122";

      # Forward other DNS queries upstream
      server = [
        "1.1.1.1"
        "8.8.8.8"
      ];

      # Only listen on Tailscale interface
      interface = "tailscale0";
      bind-interfaces = true;

      # Don't read /etc/resolv.conf
      no-resolv = true;
    };
  };

  # LiteLLM Proxy for OpenCode Zen
  services.litellm = {
    enable = true;
    host = "127.0.0.1";
    port = 4000;
    environmentFile = config.sops.secrets."litellm/env".path;

    settings = {
      model_list = [
        # Claude models via OpenCode Zen (Anthropic Messages API)
        {
          model_name = "Claude Sonnet 4.5";
          litellm_params = {
            model = "anthropic/claude-sonnet-4-5";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen";
            thinking = {
              type = "enabled";
              budget_tokens = 16000;
            };
            max_tokens = 64000;
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "Claude Opus 4.5";
          litellm_params = {
            model = "anthropic/claude-opus-4-5";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen";
            thinking = {
              type = "enabled";
              budget_tokens = 16000;
            };
            max_tokens = 64000;
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "Claude Opus 4.1";
          litellm_params = {
            model = "anthropic/claude-opus-4-1";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen";
            thinking = {
              type = "enabled";
              budget_tokens = 16000;
            };
            max_tokens = 32000;
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "Claude Sonnet 4";
          litellm_params = {
            model = "anthropic/claude-sonnet-4";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen";
            thinking = {
              type = "enabled";
              budget_tokens = 16000;
            };
            max_tokens = 64000;
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "Claude Haiku 4.5";
          litellm_params = {
            model = "anthropic/claude-haiku-4-5";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen";
            thinking = {
              type = "enabled";
              budget_tokens = 8192;
            };
            max_tokens = 64000;
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "Claude Haiku 3.5";
          litellm_params = {
            model = "anthropic/claude-3-5-haiku";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen";
          };
        }

        # GPT models via OpenCode Zen
        {
          model_name = "GPT 5.2";
          litellm_params = {
            model = "openai/gpt-5.2";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "GPT 5.2 Codex";
          litellm_params = {
            model = "openai/gpt-5.2-codex";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "GPT 5.1";
          litellm_params = {
            model = "openai/gpt-5.1";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "GPT 5.1 Codex";
          litellm_params = {
            model = "openai/gpt-5.1-codex";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "GPT 5 Nano (Free)";
          litellm_params = {
            model = "openai/gpt-5-nano";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }

        # OpenAI-compatible models
        {
          model_name = "Kimi K2";
          litellm_params = {
            model = "openai/kimi-k2";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "Qwen3 Coder 480B";
          litellm_params = {
            model = "openai/qwen3-coder";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "Big Pickle (Free)";
          litellm_params = {
            model = "openai/big-pickle";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
            thinking = {
              type = "enabled";
              budget_tokens = 8192;
            };
            max_tokens = 128000;
            merge_reasoning_content_in_choices = true;
          };
        }

        # Gemini models via OpenCode Zen
        {
          model_name = "Gemini 3 Pro";
          litellm_params = {
            model = "gemini/gemini-3-pro";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
            thinking = {
              type = "enabled";
              budget_tokens = 16000;
            };
            max_tokens = 65536;
            merge_reasoning_content_in_choices = true;
          };
        }
        {
          model_name = "Gemini 3 Flash";
          litellm_params = {
            model = "gemini/gemini-3-flash";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
            thinking = {
              type = "enabled";
              budget_tokens = 8192;
            };
            max_tokens = 65536;
            merge_reasoning_content_in_choices = true;
          };
        }
      ];
    };
  };

  system.stateVersion = "25.11";
}

{
  flake,
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
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
  services.logind.lidSwitch = "ignore";

  # # Docker registry
  # services.dockerRegistry = {
  #   enable = true;

  #   enableDelete = true;
  #   enableGarbageCollect = true;
  #   listenAddress = "0.0.0.0";
  # };

  # Acceleration
  boot.kernelParams = [
    "i915.enable_guc=2"
  ];

  hardware.opengl = {
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      libvdpau-va-gl
      intel-vaapi-driver
      libva-vdpau-driver
    ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "teemuvikoren1@gmail.com";

    certs."lab.teevik.no" = {
      domain = "*.lab.teevik.no";
      extraDomainNames = [ "lab.teevik.no" ];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = config.age.secrets.cloudflare.path;
    };
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;

    # Catch-all that returns 404 for undefined subdomains
    virtualHosts."_" = {
      default = true;
      forceSSL = true;
      useACMEHost = "lab.teevik.no";
      locations."/".return = "404";
    };

    # open-webui
    virtualHosts."chat.lab.teevik.no" = {
      forceSSL = true;
      useACMEHost = "lab.teevik.no";
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_read_timeout 300s;
          proxy_connect_timeout 300s;
          proxy_send_timeout 300s;
        '';
      };
    };
  };

  # Allow nginx to read ACME certificates
  users.users.nginx.extraGroups = [ "acme" ];

  # Open firewall for HTTPS (only on Tailscale interface)
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [
      80
      443
    ];
  };

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
    environmentFile = config.age.secrets.opencode-zen.path;

    settings = {
      model_list = [
        # Claude models via OpenCode Zen (Anthropic Messages API)
        # LiteLLM auto-appends /v1/messages, so base should be https://opencode.ai/zen
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

        # GPT models via OpenCode Zen (OpenAI Responses API)
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

        # OpenAI-compatible models (chat/completions)
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

  # OpenWebUI pointing to LiteLLM
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;
    environment = {
      OPENAI_API_BASE_URL = "http://127.0.0.1:4000/v1";
      OPENAI_API_KEY = "dummy"; # LiteLLM doesn't require auth by default
      # TODO: Declarative MCPs
    };
  };

  system.stateVersion = "25.11";
}

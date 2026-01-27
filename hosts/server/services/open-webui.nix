# Open-WebUI (AI Chat Interface) with LiteLLM backend
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

  # LiteLLM Proxy for OpenCode Zen (backend for Open-WebUI)
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
        # Claude Haiku 4.5 without thinking (for vision/image requests)
        {
          model_name = "Claude Haiku 4.5 Vision";
          litellm_params = {
            model = "anthropic/claude-haiku-4-5";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen";
            max_tokens = 4096;
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
}

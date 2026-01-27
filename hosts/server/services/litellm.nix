# LiteLLM Proxy for OpenCode Zen
# Note: This is an internal service, not exposed via the dashboard
{ config, ... }:
{
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
}

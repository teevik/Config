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

  # LiteLLM Proxy for OpenCode Zen
  services.litellm = {
    enable = true;
    host = "127.0.0.1";
    port = 4000;
    environmentFile = config.age.secrets.opencode-zen.path;

    settings = {
      model_list = [
        # Claude models via OpenCode Zen (Anthropic Messages API)
        {
          model_name = "claude-sonnet-4-5";
          litellm_params = {
            model = "anthropic/claude-sonnet-4-5";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "claude-opus-4-5";
          litellm_params = {
            model = "anthropic/claude-opus-4-5";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "claude-opus-4-1";
          litellm_params = {
            model = "anthropic/claude-opus-4-1";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "claude-sonnet-4";
          litellm_params = {
            model = "anthropic/claude-sonnet-4";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "claude-haiku-4-5";
          litellm_params = {
            model = "anthropic/claude-haiku-4-5";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "claude-haiku-3-5";
          litellm_params = {
            model = "anthropic/claude-3-5-haiku";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }

        # GPT models via OpenCode Zen (OpenAI Responses API)
        {
          model_name = "gpt-5.2";
          litellm_params = {
            model = "openai/gpt-5.2";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "gpt-5.2-codex";
          litellm_params = {
            model = "openai/gpt-5.2-codex";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "gpt-5.1";
          litellm_params = {
            model = "openai/gpt-5.1";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "gpt-5.1-codex";
          litellm_params = {
            model = "openai/gpt-5.1-codex";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "gpt-5-nano";
          litellm_params = {
            model = "openai/gpt-5-nano";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }

        # OpenAI-compatible models (chat/completions)
        {
          model_name = "kimi-k2";
          litellm_params = {
            model = "openai/kimi-k2";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "qwen3-coder";
          litellm_params = {
            model = "openai/qwen3-coder";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "big-pickle";
          litellm_params = {
            model = "openai/big-pickle";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }

        # Gemini models via OpenCode Zen
        {
          model_name = "gemini-3-pro";
          litellm_params = {
            model = "gemini/gemini-3-pro";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
          };
        }
        {
          model_name = "gemini-3-flash";
          litellm_params = {
            model = "gemini/gemini-3-flash";
            api_key = "os.environ/OPENCODE_ZEN_API_KEY";
            api_base = "https://opencode.ai/zen/v1";
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
    };
  };

  system.stateVersion = "25.11";
}

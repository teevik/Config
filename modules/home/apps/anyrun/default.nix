{ inputs, config, pkgs, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.anyrun;
in
{
  options.teevik.apps.anyrun = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable anyrun
      '';
    };
  };

  imports = [ inputs.anyrun.homeManagerModules.default ];

  config = mkIf cfg.enable {
    programs.anyrun = {
      enable = true;

      config = {
        showResultsImmediately = true;
        maxEntries = 10;

        y.fraction = 0.2;
        hidePluginInfo = true;
        ignoreExclusiveZones = true;

        plugins = with inputs.anyrun.packages.${pkgs.system}; [
          applications
          # symbols
          rink
          # shell
          # translate
          # kidex
          # :randr
          randr
          # websearch

          # :nix
          inputs.anyrun-nixos-options.packages.${pkgs.system}.default
        ];
      };

      extraConfigFiles."nixos-options.ron".text = ''
        Config(
          options: {":nixos": [".system.build.manual.optionsJSON}/share/doc/nixos/options.json"]}
        )
      '';

      extraCss =
        let
          theme = config.teevik.theme;
          colors = theme.colors.withHashtag;
        in
        ''
          window {
            background: rgba(0, 0, 0, 0.8);
          }
        '';

      # extraCss =
      #   let
      #     theme = config.teevik.theme;
      #     colors = theme.colors.withHashtag;
      #   in
      #   ''
      #     window {
      #       background: transparent; /* rgba(0, 0, 0, 0.8);*/
      #     }

      #     #match,
      #     #entry,
      #     #plugin,
      #     #main {
      #       background: transparent;
      #     }

      #     #match.activatable {
      #       padding: 120px 14px;
      #       border-radius: 12px;

      #       color: white;
      #       margin-top: 4px;
      #       border: 2px solid transparent;
      #       transition: all 0.3s ease;
      #     }

      #     #match.activatable:not(:first-child) {
      #       border-top-left-radius: 0;
      #       border-top-right-radius: 0;
      #       border-top: 2px solid rgba(255, 255, 255, 0.1);
      #     }

      #     #match.activatable #match-title {
      #       font-size: 1.3rem;
      #     }

      #     #match.activatable:hover {
      #       border: 2px solid rgba(255, 255, 255, 0.4);
      #     }

      #     #match-title, #match-desc {
      #       color: inherit;
      #     }

      #     #match.activatable:hover, #match.activatable:selected {
      #       border-top-left-radius: 12px;
      #       border-top-right-radius: 12px;
      #     }

      #     #match.activatable:selected + #match.activatable, #match.activatable:hover + #match.activatable {
      #       border-top: 2px solid transparent;
      #     }

      #     #match.activatable:selected, #match.activatable:hover:selected {
      #       background: rgba(255,255,255,0.1);
      #       border: 2px solid ${theme.borderColor};
      #       border-top: 2px solid ${theme.borderColor};
      #     }

      #     #match, #plugin {
      #       box-shadow: none;
      #     }

      #     #entry {
      #       color: white;
      #       box-shadow: none;
      #       border-radius: 12px;
      #       border: 2px solid ${theme.borderColor};
      #     }

      #     box#main {
      #       background: ${colors.base00};
      #       border-radius: 16px;
      #       padding: 8px;
      #       box-shadow: 0px 2px 33px -5px rgba(0, 0, 0, 0.5);
      #     }

      #     row:first-child {
      #       margin-top: 6px;
      #     }
      #   '';
    };
  };
}


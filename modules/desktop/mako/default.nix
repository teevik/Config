{ pkgs, lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.mako;
in
{
  options.teevik.desktop.mako = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable mako
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libnotify
    ];

    teevik.home = {
      services.mako = with config.teevik.theme.colors.withHashtag; {
        enable = true;
        defaultTimeout = 5000;

        backgroundColor = base00;
        borderColor = base0D;
        textColor = base05;
        progressColor = "over ${base02}";

        extraConfig = ''
          [urgency=low]
          background-color=${base00}
          border-color=${base0D}
          text-color=${base0A}

          [urgency=high]
          background-color=${base00}
          border-color=${base0D}
          text-color=${base08}
        '';
      };
    };
  };
}

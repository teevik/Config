{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    libnotify
  ];

  # services.mako = with config.teevik.theme.colors.withHashtag; {
  #   enable = true;
  #   defaultTimeout = 5000;

  #   backgroundColor = base00;
  #   borderColor = base0D;
  #   textColor = base05;
  #   progressColor = "over ${base02}";

  #   extraConfig = ''
  #     [urgency=low]
  #     background-color=${base00}
  #     border-color=${base0D}
  #     text-color=${base0A}

  #     [urgency=high]
  #     background-color=${base00}
  #     border-color=${base0D}
  #     text-color=${base08}
  #   '';
  # };
}

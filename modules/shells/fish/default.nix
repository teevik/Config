{ inputs, config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.shells.fish;
in
{
  options.teevik.shells.fish = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable fish
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.fish.enable = true;

    teevik.user.extraOptions.shell = pkgs.fish;

    environment.sessionVariables.EDITOR = "nvim";

    teevik.home = {
      programs.fish = {
        enable = true;

        shellInit =
          let
            theme = config.teevik.theme.colors inputs.base16-fish;
            slug = config.teevik.theme.colors.slug;
          in
          ''
            set fish_greeting

            bind \b backward-kill-word
            bind \e\[3\;5~ kill-word

            source ${theme}
            base16-${slug}
          '';

        shellAbbrs = {
          cat = "bat";
          ls = "exa";
        };
      };
    };
  };
}

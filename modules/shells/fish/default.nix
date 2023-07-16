{ config, lib, pkgs, ... }:
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

    teevik.home = {
      programs.fish = {
        enable = true;

        shellInit = ''
          set fish_greeting

          bind \b backward-kill-word
          bind \e\[3\;5~ kill-word
        '';

        shellAbbrs = {
          cat = "bat";
          ls = "exa";
          wezterm = "wezterm start --cwd .";
        };
      };
    };
  };
}

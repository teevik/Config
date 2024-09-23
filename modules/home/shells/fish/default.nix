{ inputs, config, lib, ... }:
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
    home.sessionVariables.EDITOR = "hx";

    programs.fish = {
      enable = true;

      interactiveShellInit =
        let
          theme = config.teevik.theme.colors inputs.base16-fish;
          slug = config.teevik.theme.colors.slug;
        in
        ''
          set fish_greeting

          set PATH $PATH ~/.cargo/bin

          bind \b backward-kill-word
          bind \e\[3\;5~ kill-word

          # source ${theme}
          # base16-${slug}

          functions -c fish_prompt _old_fish_prompt

          # With the original prompt function renamed, we can override with our own.
          function fish_prompt
            # Save the return status of the last command.
            set -l old_status $status

            if test -n "$SHELL_ENV"
              # Output the venv prompt; color taken from the blue of the Python logo.
              printf "%s%s%s" (set_color 4B8BBE) "($SHELL_ENV) " (set_color normal)
            end


            # Restore the return status of the previous command.
            echo "exit $old_status" | .
            # Output the original/"old" prompt.
            _old_fish_prompt
          end
        '';

      shellAbbrs = {
        # ls = "exa";
      };

      shellAliases = {
        ssh = "kitten ssh";
        I3 = "startx";
      };
    };
  };
}

{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.shells.nushell;
in
{
  options.teevik.shells.nushell = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nushell
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.nushell = {
      enable = true;

      envFile.source = ./env.nu;

      # # TODO check if needed
      # environmentVariables = builtins.mapAttrs (name: value: "\"${builtins.toString value}\"") config.home.sessionVariables;
      environmentVariables = builtins.mapAttrs (name: value: "${builtins.toString value}") config.home.sessionVariables;

      loginFile.text = /* nu */ ''
        if (tty) == "/dev/tty1" {
          Hyprland
        }
      '';

      configFile.text = with config.teevik.theme.colors.withHashtag;  /* nu */ ''
        let fish_completer = {|spans|
          fish --command $'complete "--do-complete=($spans | str join " ")"'
          | $"value(char tab)description(char newline)" + $in
          | from tsv --flexible --no-infer
        }

        let menus = []

        let keybindings = [
            {
                name: fuzzy_file
                modifier: control
                keycode: char_t
                mode: emacs
                event: {
                    send: executehostcommand
                    cmd: "commandline edit --insert (fzf --layout=reverse)"
                }
            }
        ]

        $env.config = {
          show_banner: false,
          menus: $menus,
          keybindings: $keybindings

          completions: {
            external: {
              enable: true
              completer: $fish_completer
            }
          },
          # color_config: {
          #   separator: "${base03}"
          #   leading_trailing_space_bg: "${base04}"
          #   header: "${base0B}"
          #   date: "${base0E}"
          #   filesize: "${base0D}"
          #   row_index: "${base0C}"
          #   bool: "${base08}"
          #   int: "${base0B}"
          #   duration: "${base08}"
          #   range: "${base08}"
          #   float: "${base08}"
          #   string: "${base04}"
          #   nothing: "${base08}"
          #   binary: "${base08}"
          #   cellpath: "${base08}"
          #   hints: dark_gray

          #   # base16 white on red
          #   flatshape_garbage: { fg: "${base07}" bg: "${base08}" attr: b}
          #   # if you like the regular white on red for parse errors:
          #   # flatshape_garbage: { fg: "#FFFFFF" bg: "#FF0000" attr: b}
          #   flatshape_bool: "${base0D}"
          #   flatshape_int: { fg: "${base0E}" attr: b}
          #   flatshape_float: { fg: "${base0E}" attr: b}
          #   flatshape_range: { fg: "${base0A}" attr: b}
          #   flatshape_internalcall: { fg: "${base0C}" attr: b}
          #   flatshape_external: "${base0C}"
          #   flatshape_externalarg: { fg: "${base0B}" attr: b}
          #   flatshape_literal: "${base0D}"
          #   flatshape_operator: "${base0A}"
          #   flatshape_signature: { fg: "${base0B}" attr: b}
          #   flatshape_string: "${base0B}"
          #   flatshape_filepath: "${base0D}"
          #   flatshape_globpattern: { fg: "${base0D}" attr: b}
          #   flatshape_variable: "${base0E}"
          #   flatshape_flag: { fg: "${base0D}" attr: b}
          #   flatshape_custom: {attr: b}
          # }
        }
      '';
    };
  };
}

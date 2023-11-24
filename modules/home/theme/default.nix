{ inputs, config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption;
  cfg = config.teevik.theme;

  themeType = types.submodule {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
      };

      name = mkOption {
        type = types.str;
      };
    };
  };
in
{
  options.teevik.theme = {
    background = mkOption {
      type = types.path;
      description = ''
        Path to background image
      '';
    };

    colors =
      let
        optionValueType = types.oneOf [ schemeAttrsType types.path types.str ];
        coerce = value:
          if value ? "scheme-name" then
            value
          else
            (inputs.base16.lib { inherit lib pkgs; }).mkSchemeAttrs value;
        schemeAttrsType = types.attrsOf types.anything;
      in
      mkOption {
        description = "Current scheme (scheme attrs or a path to a yaml file)";
        type = types.coercedTo optionValueType coerce schemeAttrsType;
      };

    borderColor = mkOption {
      type = types.coercedTo types.str (lib.removePrefix "#") types.str;
      description = ''
        Border color to use around windows
      '';
    };

    gtkTheme = mkOption {
      type = types.nullOr themeType;
      default = null;
      description = ''
        Specific gtk theme
      '';
    };

    gtkIconTheme = mkOption {
      type = types.nullOr themeType;
      default = null;
      description = ''
        Specific gtk icon theme
      '';
    };

    neofetchImage = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Specific neofetch image
      '';
    };

    vscodeTheme = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Vscode theme name
      '';
    };

    discordTheme = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Discord theme css file
      '';
    };

    spicetifyTheme = {
      theme = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      colorScheme = mkOption {
        type = lib.types.nullOr lib.types.str;
        default =
          if cfg.customColorScheme != null
          then "custom"
          else null;
      };

      customColorScheme = mkOption {
        type = lib.types.nullOr lib.types.attrs;
        default = null;
      };
    };

    kittyTheme = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Apply a Kitty color theme. This option takes the friendly name of
        any theme given by the command {command}`kitty +kitten themes`.
        See <https://github.com/kovidgoyal/kitty-themes>
        for more details.
      '';
      example = "Everforest Dark Medium";
    };

    helixTheme = mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Helix theme.
        See <https://github.com/helix-editor/helix/tree/master/runtime/themes>
        for a list of themes.
      '';
      example = "everforest_dark";
    };
  };
}

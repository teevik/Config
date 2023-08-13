{ inputs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.zathura;
in
{
  options.teevik.apps.zathura = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable zathura
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.zathura = {
      enable = true;

      extraConfig = builtins.readFile (config.teevik.theme.colors inputs.base16-zathura);
    };
  };
}

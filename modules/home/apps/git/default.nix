{ config
, lib
, ...
}:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.git;
in
{
  options.teevik.apps.git = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable git
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      delta.enable = true;

      userEmail = "teemu.vikoren@gmail.com";
      userName = "teevik";
      ignores = [
        ".DS_Store"
      ];

      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
    };
  };
}

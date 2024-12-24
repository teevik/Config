{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.laptop;
in
{
  options.teevik.suites.laptop = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable laptop suite
      '';
    };
  };

  config = mkIf cfg.enable {
    services.auto-cpufreq.enable = true;
    services.tlp.enable = lib.mkForce false;
  };
}

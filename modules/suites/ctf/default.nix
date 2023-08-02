{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.ctf;
in
{
  options.teevik.suites.ctf = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable ctf suite
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      teevik.rsa-cracker
      ripgrep-all
    ];
  };
}

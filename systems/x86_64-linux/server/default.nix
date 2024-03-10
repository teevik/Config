{ inputs, config, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
  ];

  teevik = {
    suites = {
      standard.enable = true;
    };

    boot = {
      enable = true;
    };
  };

  services.logind.lidSwitch = "ignore";

  systemd.timers."healthchecks" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitActiveSec = "10m";
      Unit = "healthchecks.service";
    };
  };

  systemd.services."healthchecks" = {
    script = ''
      curl https://hc-ping.com/$(cat ${config.age.secrets.healthchecks.path})/server
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  disko.devices = import ./disk-config.nix {
    disks = [ "/dev/nvme0n1" ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}

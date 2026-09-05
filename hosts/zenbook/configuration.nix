{
  config,
  inputs,
  perSystem,
  flake,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware.nix
    "${inputs.nixos-hardware}/common/cpu/intel"
    "${inputs.nixos-hardware}/common/cpu/intel/lunar-lake"
    "${inputs.nixos-hardware}/common/hidpi.nix"
    # "${inputs.nixos-hardware}/asus/battery.nix"

    inputs.disko.nixosModules.disko
    inputs.gaze.nixosModules.default
    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
    flake.nixosModules.gaming
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "zenbook";
  # Keep simultaneous heavy builds bounded on this 8-core laptop. For a
  # single large compilation, --max-jobs 1 --cores 8 can use the whole CPU.
  nix.settings = {
    # Four evaluator threads beat eight in the uncached toplevel benchmark.
    eval-cores = 4;
    max-jobs = 2;
    cores = 4;
  };
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Gaze keeps its recognition models warm in a system daemon, but opens the
  # camera only for enrollment or authentication. Use the IR sensor directly;
  # linux-enable-ir-emitter below continues to apply the ASUS emitter controls.
  services.gaze = {
    enable = true;
    package = inputs.gaze.packages.${pkgs.stdenv.hostPlatform.system}.gaze;
    mutableConfig = false;
    pam.defaultServices = [ ];
    settings = {
      cameras = {
        rgb = "";
        ir = "/dev/video2";
        emitter_enabled = false;
      };
      security.level = "medium";
      # IR liveness waits for eye motion across multiple matched frames. Turn
      # it off for first-match unlocks; the medium face threshold remains.
      liveness.enabled = false;
      auth = {
        abort_if_ssh = true;
        abort_if_lid_closed = true;
        start_delay_ms = 0;
        start_delay_scope = "screen_lock";
      };
    };
  };

  # Face or password, with both available concurrently. Keep Gaze out of every
  # other PAM service by using the empty defaultServices list above.
  security.pam.services.sudo.gaze = {
    enable = true;
    control = "sufficient";
    simultaneous = true;
  };
  security.pam.services.hyprlock.gaze = {
    enable = true;
    control = "sufficient";
    simultaneous = true;
  };
  security.pam.services.hyprlock-manual = {
    gaze = {
      enable = true;
      control = "sufficient";
      simultaneous = true;
    };

    # The manual lock is active before this runs. Delay only its first Gaze
    # scan so walking away after SUPER+L does not immediately unlock again.
    rules.auth.faceScanDelay = {
      order = config.security.pam.services.hyprlock-manual.rules.auth.gaze.order - 10;
      control = "optional";
      modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
      args = [
        "quiet"
        "${pkgs.writeShellScript "delay-manual-face-scan" ''
          ${lib.getExe' pkgs.coreutils "sleep"} 3
        ''}"
      ];
    };
  };

  # Applies the camera's saved UVC emitter setting at boot/resume. Initial
  # hardware discovery is still an explicit, one-time command after rebuild.
  services.linux-enable-ir-emitter = {
    enable = true;
    device = "video2";
  };

  # Logitech
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  networking.firewall.allowedTCPPorts = [ 9001 ];

  # Virt manager
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "teevik" ];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  networking.firewall.checkReversePath = false;
  services.resolved.enable = true;

  # services.mullvad-vpn.enable = true;
  # services.mullvad-vpn.package = pkgs.mullvad-vpn;

  environment.systemPackages = with pkgs; [
    virtiofsd
    sof-firmware
    wireguard-tools
    protonvpn-gui
  ];

  # TODO: remove when https://nixpk.gs/pr-tracker.html?pr=449133 is merged
  hardware.graphics.extraPackages = lib.mkForce (
    with pkgs;
    [
      intel-media-driver
      vpl-gpu-rt
    ]
  );

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  };

  system.stateVersion = "24.11";
}

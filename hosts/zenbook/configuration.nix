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
    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
    flake.nixosModules.gaming
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "zenbook";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

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

  environment.systemPackages = with pkgs; [
    probe-rs
    virtiofsd
    sof-firmware
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

    extraModprobeConfig = ''
      # quirk=RT711_JD1|SOC_SDW_PCH_DMIC|SOC_SDW_CODEC_MIC
      # RT711_JD1: default quirk value
      # SOC_SDW_PCH_DMIC: force enumerate DMIC connected to PCH
      # SOC_SDW_CODEC_MIC: don't enumerate DMIC connected to SoundWire CODEC
      options snd_soc_sof_sdw quirk=0x20041
      options snd_sof_pci tplg_filename=sof-lnl-cs42l43-l0-cs35l56-l23-2ch.tplg
    '';
  };

  system.replaceDependencies.replacements = [
    {
      original = pkgs.alsa-ucm-conf;
      replacement = pkgs.alsa-ucm-conf.overrideAttrs (old: {
        postInstall = ''
          cp ${./cs42l43.conf} $out/share/alsa/ucm2/sof-soundwire/cs42l43.conf

          cp -r ${./sof} $out/share/alsa/ucm2/blobs/
        '';
      });
    }
  ];

  nixpkgs.overlays = [
    (final: prev: {
      linux-firmware = prev.linux-firmware.overrideAttrs (old: {
        postInstall = ''
          cp ${./firmware/ibt-0190-0291-iml.sfi} $out/lib/firmware/intel/ibt-0190-0291-iml.sfi
          cp ${./firmware/ibt-0190-0291-usb.sfi} $out/lib/firmware/intel/ibt-0190-0291-usb.sfi
        '';
      });
    })
  ];

  # hardware.firmware = [
  #   (
  #     let
  #       model = "37xx";
  #       version = "0.0";

  #       firmware = pkgs.fetchurl {
  #         url = "https://github.com/intel/linux-npu-driver/raw/v1.13.0/firmware/bin/vpu_${model}_v${version}.bin";
  #         hash = "sha256-Mpoeq8HrwChjtHALsss/7QsFtDYAoFNsnhllU0xp3os=";
  #       };
  #     in
  #     pkgs.runCommand "intel-vpu-firmware-${model}-${version}" { } ''
  #       mkdir -p "$out/lib/firmware/intel/vpu"
  #       cp '${firmware}' "$out/lib/firmware/intel/vpu/vpu_${model}_v${version}.bin"
  #     ''
  #   )
  # ];

  system.stateVersion = "24.11";
}

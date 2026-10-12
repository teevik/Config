{
  config,
  inputs,
  flake,
  lib,
  pkgs,
  ...
}:
let
  # Temporary: nixpkgs applies VTK 9.6's vendored-PEGTL module rename to 9.5
  # as well, so vtk-9.5.2 fails to configure ("Could NOT find PEGTL") and
  # takes opencv4Full and linux-enable-ir-emitter down with it. Fixed by
  # https://github.com/NixOS/nixpkgs/pull/572295 (merged 2026-10-10). Delete
  # this block and the `package` line below once the fix reaches
  # nixos-unstable; the throw turns the obsolete workaround into a build error.
  vtkPegtlWorkaroundNeeded =
    lib.versionOlder pkgs.vtk.version "9.6" && lib.hasInfix "VTK::vtkpegtl" (pkgs.vtk.postPatch or "");
  vtk =
    if vtkPegtlWorkaroundNeeded then
      pkgs.vtk.overrideAttrs { postPatch = ""; }
    else
      throw "nixpkgs has fixed vtk's PEGTL rename; remove the vtk workaround in hosts/zenbook/configuration.nix";
  linux-enable-ir-emitter = pkgs.linux-enable-ir-emitter.override {
    python3 = pkgs.python3.override {
      packageOverrides = _: prev: {
        opencv4Full = prev.opencv4Full.override { inherit vtk; };
      };
    };
  };
in
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
  networking = {
    hostName = "zenbook";
    firewall = {
      allowedTCPPorts = [ 9001 ];
      checkReversePath = false;
    };
  };
  # Keep simultaneous heavy builds bounded on this 8-core laptop. For a
  # single large compilation, --max-jobs 1 --cores 8 can use the whole CPU.
  nix.settings = {
    # One evaluator thread per Lunar Lake P-core. Four beat eight in the
    # uncached toplevel benchmark; the LP E-cores sit on a separate cache
    # island and stall the shared heap. Re-check with nix-src #572.
    eval-cores = 4;
    max-jobs = 2;
    cores = 4;
  };
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  hardware = {
    bluetooth.enable = true;

    # Logitech
    logitech.wireless.enable = true;

    # TODO: remove when https://nixpk.gs/pr-tracker.html?pr=449133 is merged
    graphics.extraPackages = lib.mkForce (
      with pkgs;
      [
        intel-media-driver
        vpl-gpu-rt
        intel-compute-runtime
      ]
    );
  };

  services = {
    hypridle.settings = {
      general = {
        # The wrapper makes repeated lock requests idempotent.
        lock_cmd = "hyprland-idle-lock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
      };
      # No suspend listener: background jobs keep running while locked.
      listener = [
        {
          timeout = 300;
          on-timeout = "brightnessctl -s set 50%-";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 620;
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
        }
      ];
    };

    blueman.enable = true;
    resolved.enable = true;

    # Applies the camera's saved UVC emitter setting at boot/resume. Initial
    # hardware discovery is still an explicit, one-time command after rebuild.
    linux-enable-ir-emitter = {
      enable = true;
      package = linux-enable-ir-emitter;
      device = "video2";
    };

    # Gaze keeps its recognition models warm in a system daemon, but opens the
    # camera only for enrollment or authentication. Use the IR sensor directly;
    # linux-enable-ir-emitter continues to apply the ASUS emitter controls.
    gaze = {
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
  };

  # Face or password, with both available concurrently. Keep Gaze out of every
  # other PAM service by using the empty defaultServices list above.
  security.pam.services = {
    sudo.gaze = {
      enable = true;
      control = "sufficient";
      simultaneous = true;
    };
    hyprlock.gaze = {
      enable = true;
      control = "sufficient";
      simultaneous = true;
    };
    hyprlock-manual = {
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
  };

  # Logitech
  programs.solaar.enable = true;

  environment.systemPackages = with pkgs; [
    virtiofsd
    sof-firmware
    wireguard-tools
    proton-vpn
  ];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    # Log suspend/resume details, including the IRQ that woke an s2idle
    # suspend, to debug spurious wakeups and deaths while lid-closed.
    kernelParams = [ "pm_debug_messages" ];
  };

  system.stateVersion = "24.11";
}

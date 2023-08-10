{ inputs, ... }:
{
  imports = [
    inputs.nixos-apple-silicon.nixosModules.default
    ./hardware.nix
  ];

  config = {
    teevik = {
      boot = {
        enable = true;
        canTouchEfiVariables = false;
      };

      suites = {
        standard.enable = true;
        # gaming.enable = true;
        # ctf.enable = true;
      };

      # desktop.hyprland = {
      #   enableHidpi = true;
      # };

      hardware = {
        light.enable = true;

        opengl.driSupport32Bit = false;
      };
    };

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "23.11";
  };
}

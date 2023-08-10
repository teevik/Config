{ inputs, ... }:
{
  config = {
    imports = [ inputs.nixos-apple-silicon.nixosModules.default ];

    teevik = {
      boot = {
        enable = true;
        canTouchEfiVariables = false;
      };

      hardware = {
        networking.enable = true;
        firmware.enableAllFirmware = true;
      };

      apps = {
        git.enable = true;
        comma.enable = true;
      };

      # suites = {
      #   standard.enable = true;
      # };

      # boot = {
      #   enable = true;
      # };

      # desktop.hyprland = {
      #   enableHidpi = true;
      # };

      hardware = {
        light.enable = true;
      };
    };

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "23.11";
  };
}

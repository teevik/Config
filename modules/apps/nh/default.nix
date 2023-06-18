{ inputs, ... }:
{
  imports = [
    inputs.nh.nixosModules.default
  ];

  config = {
    environment.sessionVariables.FLAKE = "/home/teevik/Documents/Config";

    nh.enable = true;
  };
}

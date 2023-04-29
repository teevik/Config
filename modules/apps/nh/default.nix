{ inputs, ... }:
{
  config = {
    environment.sessionVariables.FLAKE = "/home/teevik/Documents/Config";

    environment.systemPackages = [
      inputs.nh.packages.x86_64-linux.default
    ];
  };
}

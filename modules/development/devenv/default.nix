{ inputs, system, ... }:
{
  environment.systemPackages = [
    inputs.devenv.packages.${system}.devenv
  ];
}

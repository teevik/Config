# Service modules
# Each file defines a service and registers it with lab.services
{
  imports = [
    ./lldap.nix
    ./authelia.nix
    ./open-webui.nix
    ./monitoring.nix
    ./homepage.nix
  ];
}

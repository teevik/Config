{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.eduvpn-client ];

  # eduVPN falls back to OpenVPN over TCP when WireGuard over UDP fails,
  # and imports that profile through NetworkManager's OpenVPN plugin.
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];
}

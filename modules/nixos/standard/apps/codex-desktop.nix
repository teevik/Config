{ inputs, ... }:
{
  imports = [ inputs.codex-desktop-linux.nixosModules.default ];

  # Codex Desktop from OpenAI's official Linux package, with the community
  # Computer Use backend. Input goes through /dev/uinput (pointer) and ydotoold
  # (keyboard), both enabled elsewhere; screenshots use the Hyprland portal.
  # Check readiness by asking Codex "Check whether Linux Computer Use is ready".
  programs.codexDesktopLinux = {
    enable = true;
    linuxFeatures = [ "computer-use-linux" ];
  };

  # Computer Use reads app accessibility trees over AT-SPI.
  services.gnome.at-spi2-core.enable = true;
}

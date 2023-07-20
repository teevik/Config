{ writeShellApplication, neofetch, imagemagick }:

writeShellApplication {
  name = "neofetch";

  runtimeInputs = [ neofetch imagemagick ];

  text = ''
    neofetch \
      --iterm2 ${./hyprchan.png} \
      --disable wm theme \
      --distro_shorthand on
  '';
}

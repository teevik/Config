{ writeShellApplication
, neofetch
, imagemagick
, neofetchImage ? ./hyprchan.png
}:

writeShellApplication {
  name = "neofetch";

  runtimeInputs = [ neofetch imagemagick ];

  text = ''
    neofetch \
      --iterm2 ${neofetchImage} \
      --disable wm theme icons \
      --distro_shorthand on
  '';
}

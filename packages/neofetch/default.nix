{ writeShellApplication
, neofetch
, imagemagick
, neofetchImage ? null
}:

writeShellApplication {
  name = "neofetch";

  runtimeInputs = [ neofetch imagemagick ];

  text = ''
    neofetch \
      ${if neofetchImage != null then "--kitty ${neofetchImage}" else ""} \
      --disable wm theme icons \
      --distro_shorthand on
  '';
}

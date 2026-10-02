{
  pkgs,
}:

# Point Firefox at the profile in ~/.mozilla/firefox/default when it has no
# profiles.ini yet. Firefox owns the file afterwards, so it is never rewritten.
# A dangling symlink (left by the old stowed profiles.ini) counts as missing.
let
  profilesIni = pkgs.writeText "profiles.ini" ''
    [General]
    StartWithLastProfile=1
    Version=2

    [Profile0]
    Name=default
    IsRelative=1
    Path=default
    Default=1
  '';
in
pkgs.writeShellScript "firefox-seed-profiles" ''
  PATH=${pkgs.coreutils}/bin
  dir=/home/teevik/.mozilla/firefox
  if [ ! -e "$dir/profiles.ini" ]; then
    mkdir -p "$dir/default"
    rm -f "$dir/profiles.ini"
    install -m 644 -o teevik -g users ${profilesIni} "$dir/profiles.ini"
    chown teevik:users /home/teevik/.mozilla "$dir" "$dir/default"
  fi
''

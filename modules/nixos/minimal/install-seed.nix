# `just install` (scripts/install.nu) stages private keys and the installing
# checkout in /var/lib/install-seed through nixos-anywhere --extra-files. They
# arrive owned by root because the user's UID is only allocated during
# activation, so adopt them right after the users exist. Activation runs
# before sops-nix reads the age key (see ../standard/sops) and before any
# service starts, so Hjem's first activation already finds its dotfile sources.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.users.users.teevik;
  adopt = pkgs.writeShellScript "install-seed" (builtins.readFile ./install-seed.sh);
in
{
  system.activationScripts.installSeed = lib.stringAfter [ "users" "groups" ] ''
    ${adopt} /var/lib/install-seed ${lib.escapeShellArgs [
      user.home
      user.name
      user.group
    ]}
  '';
}

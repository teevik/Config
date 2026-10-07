# Link every tracked file under dotfiles/ into teevik's home, the way
# `stow dotfiles` did. Sources are strings, not Nix paths, so the links point
# at the git checkout instead of the store and edits apply without a rebuild.
{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config.users.users.teevik) home;
  checkout = "${home}/Documents/Config/dotfiles";

  # Every file below `src`, keyed by its path relative to `src`, as a symlink
  # to the same relative path below `root`. Directories are never linked
  # whole, so programs that write next to their config stay out of the repo.
  linkTree =
    { src, root }:
    let
      relativeTo = file: lib.removePrefix "./" (toString (lib.path.removePrefix src file));
      link = file: lib.nameValuePair (relativeTo file) { source = "${root}/${relativeTo file}"; };
    in
    lib.listToAttrs (map link (lib.filesystem.listFilesRecursive src));
in
{
  imports = [ inputs.hjem.nixosModules.default ];

  hjem.users.teevik.files = linkTree {
    src = ../../../dotfiles;
    root = checkout;
  };
}

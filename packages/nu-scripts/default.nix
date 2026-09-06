{
  pkgs ? import ../nix-lint/pkgs.nix,
  ...
}:
# A binary launcher, not another shell script. Keep the caller's selected Nix
# and nix-update; only pin Nu and the non-Nix tools used by the scripts.
pkgs.runCommandLocal "config-nu"
  {
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    meta.mainProgram = "config-nu";
  }
  ''
    mkdir -p "$out/bin"
    makeWrapper ${pkgs.lib.getExe pkgs.nushell} "$out/bin/config-nu" \
      --add-flags --no-config-file \
      --prefix PATH : ${
        pkgs.lib.makeBinPath [
          pkgs.coreutils
          pkgs.nodejs
        ]
      }
  ''

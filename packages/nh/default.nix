# Source preparation hook, selected by the standard apps module.
{
  pkgs ? import ../../packages/nix-lint/pkgs.nix,
  flake ? null,
}:
let
  nh = pkgs.nh.override {
    nh-unwrapped = pkgs.nh-unwrapped.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./source-hook.patch ];
    });
  };
  prepareSource = pkgs.writeShellScript "nh-prepare-source" ''
    exec ${pkgs.bash}/bin/bash ${./prepare-source} ${pkgs.lib.escapeShellArg flake} "$@"
  '';
in
if flake == null then
  nh
else
  pkgs.symlinkJoin {
    inherit (nh) pname version meta;
    paths = [ nh ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nh --set NH_OS_FLAKE_SOURCE_COMMAND ${prepareSource}
    '';
  }

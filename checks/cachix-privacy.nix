{
  pkgs ? import ../packages/nix-lint/pkgs.nix,
  ...
}:
pkgs.runCommand "cachix-privacy-check"
  {
    nativeBuildInputs = with pkgs; [
      bash
      coreutils
    ];
  }
  ''
    cp -r ${../tests/cachix-privacy-fixtures} fixtures
    chmod -R u+w fixtures
    chmod u+x fixtures/store.sh fixtures/upload.sh
    patchShebangs fixtures
    bash ${../tests/cachix-privacy.sh} \
      ${../tests/cachix-safe-hook.sh} fixtures
    touch "$out"
  ''

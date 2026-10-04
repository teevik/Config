{ pkgs, ... }:
let
  version = "2026-10-03-c507926";
  release =
    {
      x86_64-linux = {
        arch = "x86_64";
        hash = "sha256-/g4aqfAcckzKLVZDdO6yBciOLSjIAEX1aO++H0s+DnQ=";
      };
      aarch64-linux = {
        arch = "arm64";
        hash = "sha256-4mNxysfP8hu2NTqMJ4D97PM/8n6mLBA8nwGqFIGgspI=";
      };
    }
    .${pkgs.stdenv.hostPlatform.system}
      or (throw "Roc nightly is not available for ${pkgs.stdenv.hostPlatform.system}");
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "roc-nightly";
  inherit version;

  # The rewritten compiler ships in roc-lang/nightlies, separately from the
  # older alpha/rolling compiler in roc-lang/roc. Linux binaries are static.
  src = pkgs.fetchurl {
    url = "https://github.com/roc-lang/nightlies/releases/download/nightly-${version}/roc_nightly-linux_${release.arch}-${version}.tar.gz";
    inherit (release) hash;
  };

  dontBuild = true;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 roc "$out/bin/roc"
    install -Dm644 LICENSE "$out/share/licenses/roc/LICENSE"
    install -Dm644 legal_details "$out/share/licenses/roc/legal_details"
    runHook postInstall
  '';

  doInstallCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/roc" version | grep -F "nightly-${version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Nightly build of the new Roc compiler";
    homepage = "https://www.roc-lang.org";
    changelog = "https://github.com/roc-lang/nightlies/releases/tag/nightly-${version}";
    license = pkgs.lib.licenses.upl;
    mainProgram = "roc";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
  };
}

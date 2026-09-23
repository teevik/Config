{ pkgs }:
let
  # The pinned nixpkgs Google Fonts snapshot predates this family.
  revision = "3dc14e61f108f036db84188b9b405a67df9b7c88";
  baseUrl = "https://raw.githubusercontent.com/google/fonts/${revision}/ofl/googlesansflex";
  license = pkgs.fetchurl {
    url = "${baseUrl}/OFL.txt";
    hash = "sha256-/BPWn2PjbShLbjg9TRRj2K1ATwqgZeV8+WElLVEGMTc=";
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "google-sans-flex";
  version = "0-unstable-2026-09-15";

  src = pkgs.fetchurl {
    name = "GoogleSansFlex.ttf";
    url = "${baseUrl}/GoogleSansFlex%5BGRAD%2CROND%2Copsz%2Cslnt%2Cwdth%2Cwght%5D.ttf";
    hash = "sha256-wxpIL77L8uB+aJATTSAHhyOq33Msm5xsmkT4b4Jltv4=";
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm444 "$src" "$out/share/fonts/truetype/GoogleSansFlex.ttf"
    install -Dm444 ${license} "$out/share/licenses/google-sans-flex/OFL.txt"
    runHook postInstall
  '';

  meta = {
    description = "Google Sans Flex variable interface font";
    homepage = "https://fonts.google.com/specimen/Google+Sans+Flex";
    license = pkgs.lib.licenses.ofl;
    platforms = pkgs.lib.platforms.all;
  };
}

{ fetchFromGitHub
, makeBinaryWrapper
, stdenv
, teevik
}:
let
  odin = teevik.odin;
in
stdenv.mkDerivation {
  pname = "ols";
  version = "0-unstable-2024-10-27";

  src = fetchFromGitHub {
    owner = "DanielGavin";
    repo = "ols";
    rev = "a3b090c7ef9604b0d6630caedb9c204a708828ac";
    hash = "sha256-pmxdfS8GyJneuf+ADkGyj7DZVqiyQgyNILjztxMFC0c=";
  };

  postPatch = ''
    patchShebangs build.sh odinfmt.sh
  '';

  nativeBuildInputs = [ makeBinaryWrapper ];

  buildInputs = [ odin ];

  buildPhase = ''
    runHook preBuild

    ./build.sh && ./odinfmt.sh

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 ols odinfmt -t $out/bin/
    wrapProgram $out/bin/ols --set-default ODIN_ROOT ${odin}/share

    runHook postInstall
  '';

  meta = {
    mainProgram = "ols";
  };
}

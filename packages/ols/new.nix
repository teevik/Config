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
  version = "0-unstable-2024-08-05";

  src = fetchFromGitHub {
    owner = "DanielGavin";
    repo = "ols";
    rev = "5f53ba1670b4bd44f6faf589823aa404f3c1a62b";
    hash = "sha256-4Rw3eNXkmdRMLz9k1UaK6xr0KS4g4AnFpOcrWLos2jg=";
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

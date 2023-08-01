{ lib
, fetchFromGitHub
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "lutgen-rs";
  version = "0.8.2";

  src = fetchFromGitHub {
    owner = "ozwaldorf";
    repo = "lutgen-rs";
    rev = "7a2026bb6e596474d1a90df033a0ad868b03ff81";
    hash = "sha256-9olBUPOi6ZQorgPxQX2lqZSlYjEPMwfhUF/Ze34v0nc=";
  };

  cargoHash = "sha256-XNd64MebnOxDFBZzAYl5crNosh+LksFVCMH2nDP8b1g=";

  meta = with lib; {
    description = "A blazingly fast interpolated LUT generator and applicator for arbitrary and popular color palettes";
    homepage = "https://github.com/ozwaldorf/lutgen-rs";
    mainProgram = "lutgen";
    platforms = platforms.unix;
    license = licenses.mit;
  };
}

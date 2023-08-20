{ lib
, fetchFromGitHub
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "lutgen-rs";
  version = "0.8.3";

  src = fetchFromGitHub {
    owner = "ozwaldorf";
    repo = "lutgen-rs";
    rev = "7568f2bd2ab18befeb32a9cf67ac5c5f2d95b72e";
    hash = "sha256-6vn/dlPNX6+dkIpSG7pqPAPrjEkjyBAl71JD/dlVdrU=";
  };

  cargoHash = "sha256-jnO4IX+7TUZzob0REF6h4UA1PB7fBO8kWiBL8NdAzfE=";

  meta = with lib; {
    description = "A blazingly fast interpolated LUT generator and applicator for arbitrary and popular color palettes";
    homepage = "https://github.com/ozwaldorf/lutgen-rs";
    mainProgram = "lutgen";
    platforms = platforms.unix;
    license = licenses.mit;
  };
}

{ lib
, fetchFromGitHub
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "lutgen-rs";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "ozwaldorf";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-4F4VAIyl1CgYxeNh4Z4kT+qyf5pI2PAFKLAjSPnNpg0=";
  };

  cargoHash = "sha256-Y6k2zmRktyqVdx5HkXQy770tgwIyz4y5MRtK0xf4tpM=";

  meta = with lib; {
    description = "A blazingly fast interpolated LUT generator and applicator for arbitrary and popular color palettes";
    homepage = "https://github.com/ozwaldorf/lutgen-rs";
    mainProgram = "lutgen";
    platforms = platforms.unix;
    license = licenses.mit;
  };
}

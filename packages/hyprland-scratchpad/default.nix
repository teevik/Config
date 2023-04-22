{ fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "hyprland-scratchpad";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "teevik";
    repo = "hyprland-scratchpad";
    rev = "8d7774c8ce56c205f5c5a64b75bb10b1b5e06ee2";
    hash = "sha256-Duoku9BLHA56GA6CWTCpVnfUEqaeEkkVJB8eBuZfLk8=";
  };

  cargoHash = "sha256-pKPW6S3aHw8M+zfkIv26xaWGbAGVR4FPEgc+3+bJ2LM=";
}

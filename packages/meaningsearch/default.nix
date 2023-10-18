{ rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "meaningsearch";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "kamali-sina";
    repo = "meaningsearch";
    rev = "v${version}";
    hash = "sha256-/6ciNQ54a5jddiw0n9JwdYBxrgeHb5rgbrCedmsedh4=";
  };

  cargoHash = "sha256-URPIdnzufk6Hcen1kq/GDKaj0pXHb8ggMc0S83/1Pzc=";

  meta = {
    description = "An open source CTF tool for meaning finding that supports leetspeak";
    homepage = "https://github.com/kamali-sina/meaningsearch";
  };
}

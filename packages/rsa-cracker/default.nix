{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, openssl
, gnum4
, stdenv
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "rsa-cracker";
  version = "unstable-2023-07-20";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "skyf0l";
    repo = "RsaCracker";
    rev = "f3105e3630b66fd388dc052dfc6330717743217f";
    hash = "sha256-CpEk2HczyYiMkQQoKWhaUB81cb/UbktvE6XmuXe75Ps=";
  };

  cargoHash = "sha256-fZ+8RyhEbEHJZif6/WlClpOmH0DW+oE1doo9/HOOJEo=";

  nativeBuildInputs = [
    pkg-config
    gnum4
  ];

  buildInputs = [
    openssl
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  meta = with lib; {
    description = "Powerful RSA cracker for CTFs. Supports RSA, X509, OPENSSH in PEM and DER formats";
    homepage = "https://github.com/skyf0l/RsaCracker";
    license = with licenses; [ mit asl20 ];
    maintainers = with maintainers; [ ];
  };
}

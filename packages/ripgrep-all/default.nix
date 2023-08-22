{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, bzip2
, sqlite
, xz
, zstd
}:

rustPlatform.buildRustPackage rec {
  pname = "ripgrep-all";
  version = "1.0.0-alpha.5";

  src = fetchFromGitHub {
    owner = "phiresky";
    repo = "ripgrep-all";
    rev = "v${version}";
    hash = "sha256-fpDYzn4oAz6GJQef520+Vi2xI09xFjpWdAlFIAVzcoA=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "tokio-tar-0.3.1" = "sha256-gp4UM6YV7P9k1FZxt3eVjyC4cK1zvpMjM5CPt2oVBEA=";
    };
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    bzip2
    sqlite
    xz
    zstd
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  meta = with lib; {
    description = "Rga: ripgrep, but also search in PDFs, E-Books, Office documents, zip, tar.gz, etc";
    homepage = "https://github.com/phiresky/ripgrep-all.git";
    changelog = "https://github.com/phiresky/ripgrep-all/blob/${src.rev}/CHANGELOG.md";
    license = licenses.agpl3Only;
  };
}

{ pkgs }:
pkgs.rustPlatform.buildRustPackage {
  pname = "hyprland-scratchpad";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "teevik";
    repo = "hyprland-scratchpad";
    rev = "28e4f9f794090b195a7f2cb235ccc066298c036b";
    hash = "sha256-2YNjV0xLwp6TOd18BZUkHZL+ai9YjfyyODBJFEXQPRs=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;

    outputHashes = {
      "hyprland-0.4.0-alpha.2" = "sha256-+AkB1ZltdqPn2ZRzU5FIQVWwuvm2TWhnNJnnG/oUIfI=";
    };
  };

  meta.mainProgram = "hyprland-scratchpad";
}

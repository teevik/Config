{ pkgs, ... }:
pkgs.opencode.overrideAttrs (old: rec {
  version = "1.2.27";
  src = pkgs.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-JUlFfILzcUCME3mOxdxDbcCXphNVEfVGIKhwAwtJPl8=";
  };
  patches = (old.patches or [ ]) ++ [ ./opencode-terminal-title.patch ];
  node_modules = old.node_modules.overrideAttrs {
    inherit src;
    outputHash = "sha256-byKXLpfvidfKl8PshUsW0grrRYRoVAYYlid0N6/ke2c=";
  };
})

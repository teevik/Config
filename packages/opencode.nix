{ pkgs, ... }:
pkgs.opencode.overrideAttrs (old: rec {
  version = "1.2.25";
  src = pkgs.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-gWJUkrskRYAZX29F+p5z5QnxMjD54nId9i/7jbSQV8s=";
  };
  node_modules = old.node_modules.overrideAttrs {
    inherit src;
    outputHash = "sha256-byKXLpfvidfKl8PshUsW0grrRYRoVAYYlid0N6/ke2c=";
  };
})

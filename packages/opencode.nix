{ pkgs, ... }:
pkgs.opencode.overrideAttrs (old: rec {
  version = "1.3.2";
  src = pkgs.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-04eOIBHX9e8Brwn+uL/7q8szvRUilr4G0B8eB76dhKU=";
  };
  patches = (old.patches or [ ]) ++ [ ./opencode-terminal-title.patch ];
  node_modules = old.node_modules.overrideAttrs {
    inherit src;
    outputHash = "sha256-LRLKvI1tfIebiVP6SQIs7heoOqAsB+FaCnrpFE0VLe4=";
  };
})

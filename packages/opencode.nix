{ pkgs, ... }:
pkgs.opencode.overrideAttrs (old: rec {
  version = "1.2.20";
  src = pkgs.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-FBmF7/uwZYY/qY1252Hz+XhXdE+Qp5axySAy5Jw7XUQ=";
  };
  node_modules = old.node_modules.overrideAttrs {
    inherit src;
    outputHash = "sha256-OwlJRAeKnX5YMwQgaV4op40rjt5kxsP4WrOzpp9t90w=";
  };
})

{ pkgs, ... }:
pkgs.opencode.overrideAttrs (old: rec {
  version = "1.2.24";
  src = pkgs.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-smGIc6lYWSjfmGAikoYpP7GbB6mWacrPWrRtp/+HJ3E=";
  };
  node_modules = old.node_modules.overrideAttrs {
    inherit src;
    outputHash = "sha256-twywrmswEl687u5mqWgVVzOeWOheNGuW3e4L5tq/Qbw=";
  };
})

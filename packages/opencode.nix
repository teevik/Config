{ pkgs, ... }:
pkgs.opencode.overrideAttrs (old: rec {
  version = "1.3.0";
  src = pkgs.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-JQsccVflS/GAjzguvZTLn7UH7tsou8yCSlaA48DVY10=";
  };
  patches = (old.patches or [ ]) ++ [ ./opencode-terminal-title.patch ];
  node_modules = old.node_modules.overrideAttrs {
    inherit src;
    outputHash = "sha256-K6wRsvkhKzNL727/nqAUedv0HvfJt7vu13RKKcJ9adk=";
  };
})

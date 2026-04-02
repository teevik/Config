{ pkgs, ... }:
pkgs.opencode.overrideAttrs (
  old:
  let
    oldAttrs = removeAttrs old [ "cargoDeps" ];
  in
  oldAttrs
  // rec {
    version = "1.3.13";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-P6Md0WzHK2/oAZ6VbpYnabVJyVcqwuYizoOqbxaf+lU=";
    };
    patches = (old.patches or [ ]) ++ [
      ./opencode-terminal-title.patch
    ];
    node_modules = old.node_modules.overrideAttrs {
      inherit src;
      outputHash = "sha256-fWc9xVn6HbNxnJ9S8Q+hdlYQYkdGk+4RWWbYaB+L09Q=";
    };
  }
)

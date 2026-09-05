{
  pkgs ? import ../packages/nix-lint/pkgs.nix,
  ...
}:
let
  fixtureLock.nodes = {
    root.inputs.marble = "marble";
    marble.locked.type = "github";
    kit = {
      locked = {
        type = "path";
        path = "./kit";
      };
      parent = [ "marble" ];
    };
    deferred = {
      locked.type = "git";
      buildTime = true;
    };
  };
  result = import ../tests/evaluation/prefetch-inputs.nix {
    lock = fixtureLock;
    fetchTree =
      input:
      assert input.type == "github";
      {
        outPath = ../tests/lint-fixtures;
      };
  };
  failure = builtins.tryEval (
    import ../tests/evaluation/prefetch-inputs.nix {
      lock = fixtureLock;
      fetchTree = _: throw "fetch failed";
    }
  );
in
assert result.fetchedInputs == 1;
assert result.bundledPathInputs == [ "kit" ];
assert !failure.success;
pkgs.runCommand "nix-prefetch-check" { } ''touch "$out"''

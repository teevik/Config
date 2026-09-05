# Both engines use the same source, input pins, and package definitions.
# Evaluate drvPath, not a shallow attribute such as the hostname.
{
  engine ? "blueprint",
  host ? "zenbook",
  flakeRef ? "git+file://${toString ../..}?submodules=1",
}:
let
  original = builtins.getFlake flakeRef;
  outputs = (import (original.outPath + "/flake.nix")).outputs (
    original.inputs
    // {
      self = native;
      blueprint = import ./native-prototype.nix;
    }
  );
  native = original // outputs;
  flake =
    if engine == "blueprint" then
      original
    else if engine == "native" then
      native
    else
      throw "unknown benchmark engine: ${engine}";
in
flake.nixosConfigurations.${host}.config.system.build.toplevel.drvPath

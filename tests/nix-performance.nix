# Run with and without --extra-experimental-features parallel-eval:
# nix eval --impure --json --expr 'import ./tests/nix-performance.nix {}'
{
  host ? "zenbook",
  flakeRef ? "git+file://${toString ../.}?submodules=1",
}:
let
  flake = builtins.getFlake flakeRef;
  machine = flake.nixosConfigurations.${host};
  serial = machine.extendModules {
    modules = [ { teevik.performance.parallelEvaluation = false; } ];
  };
  packageDrvs = machine: map (package: package.drvPath) machine.config.environment.systemPackages;
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  lazyLock = builtins.toFile "test-lazy-flake.lock" (
    builtins.toJSON (
      lock
      // {
        nodes = builtins.mapAttrs (
          _: node:
          if node ? locked.rev then
            node // { locked = builtins.removeAttrs node.locked [ "narHash" ]; }
          else
            node
        ) lock.nodes;
      }
    )
  );
  regularTargets = import ../packages/update-targets.nix { };
  lazyTargets = import ../packages/update-targets.nix { lockFile = lazyLock; };
  sameUpdateTargets = builtins.all (
    name: regularTargets.${name}.drvPath == lazyTargets.${name}.drvPath
  ) (builtins.attrNames regularTargets);
  sameSystem =
    machine.config.system.build.toplevel.drvPath == serial.config.system.build.toplevel.drvPath;
  samePackages = packageDrvs machine == packageDrvs serial;
in
assert sameSystem;
assert samePackages;
assert sameUpdateTargets;
{
  inherit sameSystem samePackages sameUpdateTargets;
  parallelBuiltinAvailable = builtins ? parallel;
  packageCount = builtins.length machine.config.environment.systemPackages;
}

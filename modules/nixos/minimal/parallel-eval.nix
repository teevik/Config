{ config, lib, ... }:
{
  options.teevik.performance.parallelEvaluation = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Start evaluating installed package derivations concurrently when the
      system toplevel is requested. Requires Determinate Nix with the
      parallel-eval experimental feature; other evaluators use the serial
      path. Disable this option to compare performance or diagnose issues.
    '';
  };

  options.system.build.toplevel = lib.mkOption {
    apply =
      system:
      if config.teevik.performance.parallelEvaluation && builtins ? parallel then
        # parallel only forces each task to weak head normal form. Schedule
        # drvPath strings, not package attrsets, to do the expensive work.
        # These are the SAME thunks that the system build will demand, so
        # workers share results instead of importing/evaluating a second pkgs.
        builtins.parallel (map (package: package.drvPath) config.environment.systemPackages) system
      else
        system;
  };
}

# Package a standalone Nu script with pinned tools and a mandatory parse check.
{ pkgs }:
{
  name,
  script,
  runtimeInputs ? [ ],
  runtimeEnv ? { },
}:
let
  application = pkgs.writers.writeNuBin name {
    check = "${pkgs.lib.getExe pkgs.nushell} --no-config-file ${./check.nu}";
  } script;
  wrapperArgs =
    pkgs.lib.optionals (runtimeInputs != [ ]) [
      "--prefix"
      "PATH"
      ":"
      (pkgs.lib.makeBinPath runtimeInputs)
    ]
    ++ pkgs.lib.concatMap (key: [
      "--set"
      key
      (if builtins.isPath runtimeEnv.${key} then "${runtimeEnv.${key}}" else toString runtimeEnv.${key})
    ]) (builtins.attrNames runtimeEnv);
in
# The pinned writer expands makeWrapperArgs without quoting its array. Wrap
# separately so whitespace, quotes, and shell metacharacters remain literal.
application.overrideAttrs (old: {
  buildCommand =
    old.buildCommand
    + pkgs.lib.optionalString (wrapperArgs != [ ]) ''
      wrapProgram "$out/bin/${name}" ${pkgs.lib.escapeShellArgs wrapperArgs}
    '';
})

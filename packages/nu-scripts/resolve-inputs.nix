{ root }:
let
  inputs = (import (root + "/flake.nix")).inputs or { };
  names = builtins.filter (name: name != "self" && !(inputs.${name} ? follows)) (
    builtins.attrNames inputs
  );
  supported = builtins.all (
    name:
    let
      input = inputs.${name};
    in
    input ? url
    && builtins.all (
      key:
      builtins.elem key [
        "url"
        "inputs"
        "flake"
      ]
    ) (builtins.attrNames input)
    && builtins.elem (builtins.parseFlakeRef input.url).type [
      "github"
      "git"
      "tarball"
    ]
  ) names;
  tasks = builtins.map (
    name:
    let
      original = builtins.parseFlakeRef inputs.${name}.url;
      fetched = builtins.fetchTree (builtins.removeAttrs original [ "dir" ]);
      locked =
        (if original.type == "github" then builtins.removeAttrs original [ "ref" ] else original)
        // (if fetched ? rev then { inherit (fetched) rev; } else { inherit (fetched) narHash; });
    in
    {
      inherit name original;
      resolved = builtins.flakeRefToString locked;
    }
  ) names;
in
{
  # Ordinary Nix, indirect/path inputs, and structured fetcher declarations use
  # the native updater. Only remote resolution needs the parallel evaluator.
  result =
    if builtins ? parallel && supported then
      builtins.parallel (map (task: builtins.deepSeq task true) tasks) tasks
    else
      [ ];
}

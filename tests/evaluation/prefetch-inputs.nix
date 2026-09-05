# Determinate 3.22.3's native prefetch-inputs loses relative-path parent context.
# Fetch locked remote trees directly; local/bundled path inputs need no download.
# Reading the directory forces each fetch without evaluating any flake outputs.
{
  lock ? builtins.fromJSON (builtins.readFile ../../flake.lock),
  fetchTree ? builtins.fetchTree,
}:
let
  nodes = builtins.attrValues lock.nodes;
  remote = builtins.filter (
    node: node ? locked && node.locked.type != "path" && !(node.buildTime or false)
  ) nodes;
  bundledPathInputs = builtins.filter (name: (lock.nodes.${name}.locked.type or null) == "path") (
    builtins.attrNames lock.nodes
  );
  tasks = map (node: builtins.deepSeq (builtins.readDir (fetchTree node.locked).outPath) true) remote;
  result = builtins.deepSeq tasks {
    fetchedInputs = builtins.length remote;
    inherit bundledPathInputs;
  };
in
if builtins ? parallel then builtins.parallel tasks result else result

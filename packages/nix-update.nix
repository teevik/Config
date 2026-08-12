{
  system ? builtins.currentSystem,
}:
let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  nixpkgsLocked = lock.nodes.${lock.nodes.root.inputs.nixpkgs}.locked;
  llmAgentsLocked = lock.nodes.${lock.nodes.root.inputs."llm-agents"}.locked;
  nixpkgs = builtins.fetchTree {
    inherit (nixpkgsLocked)
      narHash
      owner
      repo
      rev
      type
      ;
  };
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  llmAgents = builtins.getFlake "github:${llmAgentsLocked.owner}/${llmAgentsLocked.repo}/${llmAgentsLocked.rev}";
  perSystem.llm-agents = llmAgents.packages.${system};
in
{
  opencode = import ./opencode.nix { inherit pkgs; };
  omp = perSystem.llm-agents.omp;
  t3code-nightly = import ./t3code-nightly.nix { inherit perSystem pkgs; };
}

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
  # Match flake.nix: keep upstream's package set for cache compatibility,
  # but don't evaluate platform metadata for the entire agent catalog.
  agentPkgs = import llmAgents.inputs.nixpkgs { inherit system; };
  perSystem = {
    llm-agents = (llmAgents.overlays.shared-nixpkgs agentPkgs agentPkgs).llm-agents;
    self.opencode = opencode;
  };
  opencode = import ./opencode.nix { inherit pkgs; };
in
{
  inherit opencode;
  opencode-desktop = import ./opencode-desktop.nix { inherit perSystem pkgs; };
  omp = perSystem.llm-agents.omp;
  t3code-nightly = import ./t3code-nightly.nix { inherit perSystem pkgs; };
}

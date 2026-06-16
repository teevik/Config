{
  system ? builtins.currentSystem,
}:
let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  nixpkgsLocked = lock.nodes.${lock.nodes.root.inputs.nixpkgs}.locked;
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
in
{
  opencode = import ./opencode.nix { inherit pkgs; };
}

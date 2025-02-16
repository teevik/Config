{
  description = "Simple flake with a devshell";

  # Add all your dependencies here
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Load the blueprint
  outputs = inputs: inputs.blueprint { inherit inputs; };
}

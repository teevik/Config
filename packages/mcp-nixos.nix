{
  inputs,
  pkgs,
}:
let
  inherit (inputs)
    uv2nix
    pyproject-nix
    pyproject-build-systems
    mcp-nixos
    ;
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = "${mcp-nixos}"; };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  python = pkgs.python312;

  pythonSet =
    # Use base package set from pyproject.nix builders
    (pkgs.callPackage pyproject-nix.build.packages {
      inherit python;
    }).overrideScope
      (
        pkgs.lib.composeManyExtensions [
          pyproject-build-systems.overlays.default
          overlay
        ]
      );

  inherit (pkgs.callPackages pyproject-nix.build.util { }) mkApplication;
in

mkApplication {
  venv = pythonSet.mkVirtualEnv "mcp-nixos-env" workspace.deps.default;
  package = pythonSet.mcp-nixos;
}

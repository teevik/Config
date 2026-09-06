# Package the hook with the action's exact executable paths. Do not substitute
# nixpkgs.nix: the caller supplies its selected Determinate nix-store executable.
{
  pkgs ? import ../packages/nix-lint/pkgs.nix,
  originalHook,
  nixStoreBin,
}:
(import ../packages/nu-scripts/write-application.nix { inherit pkgs; }) {
  name = "cachix-safe-hook";
  script = ./cachix-safe-hook.nu;
  runtimeEnv = {
    CACHIX_ORIGINAL_HOOK = originalHook;
    NIX_STORE_BIN = nixStoreBin;
  };
}

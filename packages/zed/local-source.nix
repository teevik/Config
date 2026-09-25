{ pkgs, source }:
relative:
let
  inherit (pkgs) lib;
  manifest = builtins.fromTOML (builtins.readFile "${source}/${relative}/Cargo.toml");
  inherit (builtins.fromTOML (builtins.readFile "${source}/Cargo.toml")) workspace;
  inherited = lib.filterAttrs (
    _: value: builtins.isAttrs value && (value.workspace or false)
  ) manifest.package;
  # The native builder resolves dependencies separately and invokes rustc
  # directly. It only walks up to this manifest for package inheritance.
  # Keep exactly those fields; unrelated workspace dependency edits must
  # not change every crate's build inputs.
  workspaceManifest = (pkgs.formats.toml { }).generate "zed-workspace-package.toml" {
    workspace.package = lib.genAttrs (builtins.attrNames inherited) (name: workspace.package.${name});
  };
  extras = {
    "crates/assets" = [ "assets" ];
    "crates/settings" = [ "assets" ];
    "crates/release_channel" = [ "crates/zed/RELEASE_CHANNEL" ];
    "crates/prompt_store" = [ "crates/git_ui/src/commit_message_prompt.txt" ];
    "crates/cli" = [ "script/uninstall.sh" ];
    "crates/extension_host" = [ "crates/extension_api/wit" ];
  };
  paths = [
    relative
  ]
  ++ (extras.${relative} or [ ]);
in
{
  workspace_member = relative;
  postPatch = ''
    cp ${workspaceManifest} Cargo.toml
  '';
  src = lib.cleanSourceWith {
    src = source;
    name = "source";
    filter =
      path: type:
      let
        relativePath = lib.removePrefix "${source}/" path;
      in
      builtins.any (
        included:
        relativePath == included
        || lib.hasPrefix "${included}/" relativePath
        || (type == "directory" && lib.hasPrefix "${relativePath}/" included)
      ) paths;
  };
}

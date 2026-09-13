{
  inputs,
  pkgs,
  system,
  ...
}:
let
  # Apply the local Crane optimizations to Zed's locked build inputs.
  withInputs =
    flake: overrides:
    let
      inputs = flake.inputs // overrides;
      outputs = (import (flake.outPath + "/flake.nix")).outputs (inputs // { self = result; });
      result = flake // outputs // { inherit inputs outputs; };
    in
    result;
  upstream = inputs.zed;
  zed = withInputs inputs.zed {
    crane = import ./crane.nix upstream.inputs.crane;
  };
in
zed.packages.${system}.default.overrideAttrs (oldAttrs: {
  # Keep the stable channel used by the existing installation.
  preBuild = (oldAttrs.preBuild or "") + ''
    echo stable > crates/zed/RELEASE_CHANNEL
  '';

  # Use nixpkgs' WebRTC until the upstream build is fixed:
  # https://github.com/zed-industries/zed/issues/54225
  env = (oldAttrs.env or { }) // {
    LK_CUSTOM_WEBRTC = pkgs.livekit-libwebrtc;
  };
  cargoArtifacts = oldAttrs.cargoArtifacts.overrideAttrs (oldArtifacts: {
    env = (oldArtifacts.env or { }) // {
      LK_CUSTOM_WEBRTC = pkgs.livekit-libwebrtc;
    };
  });
})

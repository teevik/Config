{ pkgs, ... }:
let
  version = "0.3.1";
  release =
    {
      x86_64-linux = {
        target = "x86_64-unknown-linux-gnu";
        hash = "sha256-7b46t8ykc1/VbOiKdbEvULalBFDtFKLRlj3qEcH1apQ=";
      };
      aarch64-linux = {
        target = "aarch64-unknown-linux-gnu";
        hash = "sha256-aF3O1K4t6BES/lYZxdAw8To6Tcqf7eqXSCguYWyQjgo=";
      };
    }
    .${pkgs.stdenv.hostPlatform.system};
  runtimeInputs = [
    pkgs.bubblewrap
    pkgs.ffmpeg-headless
    pkgs.imagemagick
    pkgs.openbox
    pkgs.slirp4netns
    pkgs.util-linux
    pkgs.xclip
    pkgs.xdotool
    pkgs.xdg-utils
    pkgs.xauth
    pkgs.xdpyinfo
    pkgs.xorg-server
    pkgs.xprop
  ];
in
pkgs.stdenv.mkDerivation {
  pname = "agent-workspace-linux";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/agent-sh/agent-workspace-linux/releases/download/v${version}/agent-workspace-linux-${release.target}";
    inherit (release) hash;
  };

  dontUnpack = true;

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.makeWrapper
  ];

  buildInputs = [
    pkgs.libxcb
    pkgs.libxkbcommon
    pkgs.stdenv.cc.cc.lib
  ];

  runtimeDependencies = [
    pkgs.vulkan-loader
    pkgs.wayland
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/agent-workspace-linux"
    wrapProgram "$out/bin/agent-workspace-linux" \
      --prefix PATH : ${pkgs.lib.makeBinPath runtimeInputs}

    runHook postInstall
  '';

  meta = {
    description = "Isolated Linux desktop workspaces for AI agents";
    homepage = "https://github.com/agent-sh/agent-workspace-linux";
    changelog = "https://github.com/agent-sh/agent-workspace-linux/releases/tag/v${version}";
    license = pkgs.lib.licenses.mit;
    mainProgram = "agent-workspace-linux";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

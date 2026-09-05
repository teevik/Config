{
  perSystem,
  pkgs,
  ...
}:
let
  inherit (pkgs) appimageTools lib;

  pname = "opencode-desktop";
  inherit (perSystem.self.opencode) version;

  release =
    {
      x86_64-linux = {
        arch = "x86_64";
        hash = "sha256-NIWU1dVNpR6uComt0vO/kT8uBuOIBSYVlgc7JGzbAfM=";
      };
      aarch64-linux = {
        arch = "arm64";
        hash = "sha256-H1y9tjs3+I9OtfyJCrQN+cyBd/3egDZCX1jdCjJNbDs=";
      };
    }
    .${pkgs.stdenv.hostPlatform.system}
      or (throw "OpenCode 2 desktop is not available for ${pkgs.stdenv.hostPlatform.system}");

  src = pkgs.fetchurl {
    url = "https://github.com/anomalyco/opencode-beta/releases/download/v${version}/opencode-desktop-linux-${release.arch}.AppImage";
    inherit (release) hash;
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;

    postExtract = ''
      ${lib.getExe pkgs.asar} extract $out/resources/app.asar app
      ${pkgs.perl}/bin/perl -0pi -e '
        my $changes = s/([A-Za-z_\$][A-Za-z0-9_\$]*)=([A-Za-z_\$][A-Za-z0-9_\$]*)\.isPackaged&&!0,/$1=!1,/;
        die "expected to disable the desktop auto-updater\n" unless $changes == 1;
      ' app/out/main/index.js
      ${lib.getExe pkgs.asar} pack app $out/resources/app.asar
      rm -rf app
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

  extraInstallCommands = ''
    install -Dm644 \
      ${appimageContents}/ai.opencode.desktop.beta.desktop \
      $out/share/applications/ai.opencode.desktop.beta.desktop
    substituteInPlace $out/share/applications/ai.opencode.desktop.beta.desktop \
      --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=opencode-desktop --no-sandbox %U"

    install -Dm644 \
      ${appimageContents}/ai.opencode.desktop.beta.png \
      $out/share/icons/hicolor/512x512/apps/ai.opencode.desktop.beta.png

    . ${pkgs.makeWrapper}/nix-support/setup-hook
    wrapProgram $out/bin/opencode-desktop \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  passthru = {
    inherit appimageContents;
  };

  meta = {
    description = "OpenCode 2 desktop client";
    homepage = "https://opencode.ai/v2/docs";
    changelog = "https://github.com/anomalyco/opencode-beta/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "opencode-desktop";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

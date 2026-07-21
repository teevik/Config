{ pkgs, ... }:

let
  inherit (pkgs) appimageTools fetchurl lib;

  pname = "figma-linux";
  version = "126.5.6";

  src = fetchurl {
    url = "https://github.com/IliyaBrook/figma-linux/releases/download/${version}/figma-desktop-${version}-amd64.AppImage";
    hash = "sha256-SLn4y+NVCcBDZrGqIpmpIEQavY7xngt5JMI8yG1g6/0=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
    postExtract = ''
      substituteInPlace $out/AppRun \
        --replace-fail \
          "integrate_desktop 2>/dev/null || true" \
          ": # Desktop integration is managed declaratively by NixOS"
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

  extraInstallCommands = ''
    install -Dm444 \
      ${appimageContents}/io.github.nickvdp.figma-desktop-linux.desktop \
      $out/share/applications/figma-linux.desktop
    substituteInPlace $out/share/applications/figma-linux.desktop \
      --replace-fail "Exec=AppRun %u" "Exec=figma-linux %u"

    install -Dm444 \
      ${appimageContents}/usr/share/icons/hicolor/256x256/apps/io.github.nickvdp.figma-desktop-linux.png \
      $out/share/icons/hicolor/256x256/apps/io.github.nickvdp.figma-desktop-linux.png
  '';

  meta = {
    description = "Unofficial Linux build of Figma Desktop with MCP server support";
    homepage = "https://github.com/IliyaBrook/figma-linux";
    changelog = "https://github.com/IliyaBrook/figma-linux/releases/tag/${version}";
    license = lib.licenses.unfree;
    mainProgram = "figma-linux";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

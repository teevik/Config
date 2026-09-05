{ pkgs, ... }:
let
  inherit (pkgs) lib stdenv;

  version = "0.0.0-beta-19151";

  platform =
    {
      x86_64-linux = {
        packageName = "cli-linux-x64-baseline";
        hash = "sha512-BHDv/03Lg2Lc/+zZ6tGfs8JBkRrSy0q4Fu3L+Iq/Mmvnh1pvDRvstev7ycSN8gVRIV79epjcwoiM8gONvvQPEg==";
      };
      aarch64-linux = {
        packageName = "cli-linux-arm64";
        hash = "sha512-o1HtoNl/SxRFh/vj+YAwC9sa0YV9Ozpue6l2ZdLeuIA/eN6STwSFyYaLxFEs3HjpuVR0HRi/DgIVjHvDIh7p5g==";
      };
    }
    .${stdenv.hostPlatform.system}
      or (throw "opencode v2 beta is not available for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "opencode";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opencode-ai/${platform.packageName}/-/${platform.packageName}-${version}.tgz";
    inherit (platform) hash;
  };

  sourceRoot = "package";

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];
  buildInputs = [ pkgs.glibc ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/opencode
    cp -R bin/. $out/lib/opencode/
    chmod +x $out/lib/opencode/opencode2
    ln -s $out/lib/opencode/opencode2 $out/bin/opencode2

    runHook postInstall
  '';

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://v2.opencode.ai/";
    license = lib.licenses.mit;
    mainProgram = "opencode2";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

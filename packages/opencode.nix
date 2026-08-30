{ pkgs, ... }:
let
  inherit (pkgs) lib stdenv;

  version = "0.0.0-beta-18684";

  platform =
    {
      x86_64-linux = {
        packageName = "cli-linux-x64-baseline";
        hash = "sha512-IV5ssBZx8mt+eXq9H4s1bPcWHWDMC48G+YXCIBSDNEiURlxOGEcuygTDo+8MZ7DwIWeYi1dbDNSYtXZKhQBRbw==";
      };
      aarch64-linux = {
        packageName = "cli-linux-arm64";
        hash = "sha512-TMs+aLrLj3MsQ5407Ip9X7B9O9DCnwwlMPGu9U66OLOlj8pn3FGv9GBo4+vQZjxS8OYbXTFL8l9SYZnglMD3ug==";
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

{ fetchFromGitHub
, lib
, llvmPackages
, makeBinaryWrapper
, which
,
}:

let
  inherit (llvmPackages) stdenv;
in
stdenv.mkDerivation {
  pname = "odin";
  version = "0-unstable-2024-08-05";

  src = fetchFromGitHub {
    owner = "odin-lang";
    repo = "Odin";
    rev = "a1c3c38f0453dcf94ba13d572fa392cb5331a878";
    hash = "sha256-LYUy/llW3BFnRx6sdTF/8QdvK/v+5/ShKJR+ZXocC+4=";
  };

  postPatch =
    ''
      substituteInPlace build_odin.sh \
          --replace-fail '-framework System' '-lSystem'
      patchShebangs build_odin.sh
    '';

  LLVM_CONFIG = "${llvmPackages.llvm.dev}/bin/llvm-config";

  dontConfigure = true;

  buildFlags = [ "release" ];

  nativeBuildInputs = [
    makeBinaryWrapper
    which
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp odin $out/bin/odin

    mkdir -p $out/share
    cp -r {base,core,vendor,shared} $out/share

    wrapProgram $out/bin/odin \
      --prefix PATH : ${
        lib.makeBinPath (
          with llvmPackages;
          [
            bintools
            llvm
            clang
            lld
          ]
        )
      } \
      --set-default ODIN_ROOT $out/share

    runHook postInstall
  '';

  meta = {
    mainProgram = "odin";
  };
}

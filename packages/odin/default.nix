{ fetchFromGitHub
, lib
, llvmPackages
, makeBinaryWrapper
, nix-update-script
, which
}:

let
  inherit (llvmPackages) stdenv;
in
stdenv.mkDerivation rec {
  pname = "odin";
  version = "dev-2024-05";

  src = fetchFromGitHub {
    owner = "odin-lang";
    repo = "Odin";
    rev = version;
    hash = "sha256-JGTC+Gi5mkHQHvd5CmEzrhi1muzWf1rUN4f5FT5K5vc=";
  };

  postPatch = ''
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

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Fast, concise, readable, pragmatic and open sourced programming language";
    downloadPage = "https://github.com/odin-lang/Odin";
    homepage = "https://odin-lang.org/";
    license = lib.licenses.bsd3;
    mainProgram = "odin";
    maintainers = with lib.maintainers; [
      astavie
      luc65r
      znaniye
    ];
    platforms = lib.platforms.unix;
    broken = stdenv.hostPlatform.isMusl;
  };
}

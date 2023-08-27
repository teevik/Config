{ lib, stdenv, fetchFromGitHub, makeWrapper, perlPackages }:
stdenv.mkDerivation {
  pname = "asciiquarium";
  version = "1.2";

  src = fetchFromGitHub {
    owner = "nothub";
    repo = "asciiquarium";
    rev = "653cd99a611080c776d18fc7991ae5dd924c72ce";
    hash = "sha256-72LRFydbObFDXJllmlRjr5O8qjDqtlp3JunE3kwb5aU=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ perlPackages.perl ];

  installPhase = ''
    mkdir -p $out/bin
    cp asciiquarium $out/bin
    chmod +x $out/bin/asciiquarium
    wrapProgram $out/bin/asciiquarium \
      --set PERL5LIB ${perlPackages.makeFullPerlPath [ perlPackages.TermAnimation ] } \
      --add-flags "--transparent"
  '';

  meta = with lib; {
    description = "Enjoy the mysteries of the sea from the safety of your own terminal!";
    homepage = "https://github.com/nothub/asciiquarium";
    license = licenses.gpl2;
    platforms = platforms.unix;
  };
}

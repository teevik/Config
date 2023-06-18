{ stdenv, fetchFromGitHub }:

let flavour = "mocha"; in
stdenv.mkDerivation {
  name = "cascade";
  src = fetchFromGitHub {
    owner = "andreasgrafen";
    repo = "cascade";
    rev = "a89173a67696a8bf43e8e2ac7ed93ba7903d7a70";
    hash = "sha256-D4ZZPm/li1Eoo1TmDS/lI2MAlgosNGOOk4qODqIaCes=";
  };

  # Replace files as described in:
  # https://github.com/andreasgrafen/cascade#catppuccin
  installPhase = ''
    mkdir -p $out

    cp ./integrations/catppuccin/*.css ./chrome/includes

    substituteInPlace ./chrome/userChrome.css  \
      --replace "colours" "${flavour}" \
      --replace "includes/cascade-colours" "$out/chrome/includes/"

    cp -r * $out
  '';
}

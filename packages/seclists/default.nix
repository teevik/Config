{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "seclists";
  version = "2023.2";

  src = fetchFromGitHub {
    owner = "danielmiessler";
    repo = "SecLists";
    rev = version;
    hash = "sha256-yVxb5GaQDuCsyjIV+oZzNUEFoq6gMPeaIeQviwGdAgY=";
  };

  installPhase = ''
    cp -r . $out

    tar -xvzf $out/Passwords/Leaked-Databases/rockyou.txt.tar.gz -C $out/Passwords/Leaked-Databases
    rm $out/Passwords/Leaked-Databases/rockyou.txt.tar.gz
  '';

  meta = with lib; {
    description = "SecLists is the security tester's companion. It's a collection of multiple types of lists used during security assessments, collected in one place. List types include usernames, passwords, URLs, sensitive data patterns, fuzzing payloads, web shells, and many more";
    homepage = "https://github.com/danielmiessler/SecLists/";
    license = licenses.mit;
  };
}

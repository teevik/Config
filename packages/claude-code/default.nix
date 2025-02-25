{ pkgs }:
let
  inherit (pkgs) buildNpmPackage fetchzip;
in

buildNpmPackage rec {
  pname = "claude-code";
  version = "0.2.9";

  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-NB+pfpXrjTvvs4o81dsLhyOCvDBCF6ANkAgTnxCaF9Q=";
  };

  npmDepsHash = "sha256-quhEENiVL6PL9BjTWv3+LTgRyR+JrFA16gL05MIkOKs=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  AUTHORIZED = "1";

  meta = {
    description = "An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    downloadPage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
    mainProgram = "claude";
  };
}

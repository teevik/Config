# nix build --no-link --file tests/t3code-licenses.nix
let
  pkgs = import ../packages/nix-lint/pkgs.nix;
  t3code = (import ../packages/update-targets.nix { }).t3code-nightly.unwrapped;
in
pkgs.runCommand "t3code-license-cache-check" { nativeBuildInputs = [ pkgs.nodejs_24 ]; } ''
  cp -r ${t3code.src} source
  chmod -R u+w source
  cd source
  ${t3code.postPatch or ""}

  node --input-type=module <<'JS'
  import { syncThirdPartyLicenseNotices } from './scripts/lib/third-party-licenses.ts';
  globalThis.fetch = () => { throw new Error('Unexpected build-time SPDX download'); };
  await syncThirdPartyLicenseNotices('third-party-licenses.config.json');
  console.log('PASS: all configured license notices resolve without network access');
  JS
  touch "$out"
''

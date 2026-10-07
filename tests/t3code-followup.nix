# nix build --no-link --print-build-logs --file tests/t3code-followup.nix
let
  t3code = (import ../packages/update-targets.nix { }).t3code-nightly.unwrapped;
in
t3code.overrideAttrs (_: {
  pname = "t3code-followup-check";
  outputs = [ "out" ];
  buildPhase = ''
    runHook preBuild
    pnpm exec vp test run \
      packages/client-runtime/src/codexMarkdownDirectives.test.ts \
      packages/client-runtime/src/codexArtifactTemplates.test.ts \
      apps/web/src/components/ChatMarkdown.test.tsx \
      apps/web/src/components/ChatView.logic.test.ts \
      apps/web/src/components/chat/MessagesTimeline.logic.test.ts \
      apps/web/src/markdown-math.test.ts \
      apps/web/src/markdown-clipboard.math.test.ts
    runHook postBuild
  '';
  installPhase = ''
    touch "$out"
  '';
  postInstall = "";
  dontFixup = true;
  postFixup = "";
  doInstallCheck = false;
  postInstallCheck = "";
})

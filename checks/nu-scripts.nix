{
  pkgs ? import ../packages/nix-lint/pkgs.nix,
  ...
}:
let
  writeNuApplication = import ../packages/nu-scripts/write-application.nix { inherit pkgs; };
  mockCommand =
    name:
    writeNuApplication {
      inherit name;
      script = ../tests/nu-fixtures/command.nu;
      runtimeEnv.MOCK_TOOL = name;
    };
  probe = writeNuApplication {
    name = "nu-helper-probe";
    script = ../tests/nu-fixtures/helper.nu;
    runtimeInputs = [ pkgs.hello ];
    runtimeEnv = {
      NU_WRITER_FIXTURE = pkgs.writeText "nu-writer-fixture" "pinned fixture\n";
      NU_WRITER_VALUE = ''spaces and "quotes" $HOME ; *'';
    };
  };
  source = pkgs.lib.fileset.toSource {
    root = ../.;
    fileset = pkgs.lib.fileset.unions [
      ../packages
      ../tests
    ];
  };
in
pkgs.runCommand "nu-scripts-check"
  {
    nativeBuildInputs = map mockCommand [
      "nix"
      "nix-update"
      "npm"
    ];
  }
  ''
    ${pkgs.lib.getExe pkgs.nushell} --no-config-file \
      ${source}/tests/nu-scripts.nu ${source} ${pkgs.lib.getExe probe}
    touch "$out"
  ''

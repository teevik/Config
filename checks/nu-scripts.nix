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
      ../dotfiles/.config/nushell/config.nu
    ];
  };
in
pkgs.runCommand "nu-scripts-check"
  {
    nativeBuildInputs = map mockCommand [
      "nix"
      "git"
      "curl"
    ];
  }
  ''
    ${pkgs.lib.getExe pkgs.nushell} --no-config-file \
      ${source}/tests/nu-scripts.nu ${source} ${pkgs.lib.getExe probe}
    ${pkgs.lib.getExe pkgs.nushell} --no-config-file \
      ${source}/tests/package-update.nu ${source}
    PATH=${pkgs.lib.makeBinPath [ pkgs.nushell ]}:$PATH \
      ${pkgs.lib.getExe pkgs.python3} ${source}/tests/terminal-wrapper.py
    touch "$out"
  ''

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
  nixosAnywhere = writeNuApplication {
    name = "nixos-anywhere";
    script = ../tests/nu-fixtures/nixos-anywhere.nu;
  };
  source = pkgs.lib.fileset.toSource {
    root = ../.;
    fileset = pkgs.lib.fileset.unions [
      ../packages
      ../scripts
      ../tests
      ../modules/nixos/minimal/install-seed.nix
      ../modules/nixos/minimal/install-seed.sh
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
    # The bootstrap test snapshots a real repository, so real Git goes first.
    PATH=${pkgs.lib.makeBinPath [ nixosAnywhere pkgs.git ]}:$PATH \
      ${pkgs.lib.getExe pkgs.nushell} --no-config-file ${source}/tests/install.nu ${source}
    PATH=${pkgs.lib.makeBinPath [ pkgs.nushell ]}:$PATH \
      ${pkgs.lib.getExe pkgs.python3} ${source}/tests/terminal-wrapper.py
    touch "$out"
  ''

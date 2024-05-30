{ pkgs, ... }:
pkgs.writeShellScriptBin "copilot" ''
  ${pkgs.nodejs}/bin/node ${pkgs.vimPlugins.copilot-vim}/dist/agent.js $@
''

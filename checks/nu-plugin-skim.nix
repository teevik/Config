{ pkgs, ... }:

# Keep the former package override's protocol compatibility check separate so
# the plugin itself can use nixpkgs's cached output.
pkgs.runCommand "nu-plugin-skim-check" { nativeBuildInputs = [ pkgs.nushell ]; } ''
  export SKIM_PLUGIN_REGISTRY="$PWD/skim-plugins.msgpackz"
  nu --no-config-file -c 'plugin add --plugin-config $env.SKIM_PLUGIN_REGISTRY ${pkgs.nushellPlugins.skim}/bin/nu_plugin_skim'
  touch "$out"
''

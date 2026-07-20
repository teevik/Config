{ lib, pkgs, ... }:
let
  completionNames = [
    "as"
    "cargo"
    "claude"
    "curl"
    "docker"
    "gh"
    "git"
    "just"
    "less"
    "man"
    "nano"
    "nix"
    "npm"
    "op"
    "pnpm"
    "rg"
    "rustup"
    "ssh"
    "tar"
    "tldr"
    "typst"
    "uv"
    "yarn"
    "zig"
    "zoxide"
  ];

  nuCompletions = pkgs.writeText "nushell-completions.nu" (
    lib.concatMapStringsSep "\n" (
      name:
      "export use ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${name}/${name}-completions.nu *"
    ) completionNames
  );

  fzfIntegration = pkgs.runCommand "fzf-nushell-integration.nu" { } ''
    ${pkgs.fzf}/bin/fzf --nushell > "$out"
  '';

  zoxideIntegration = pkgs.runCommand "zoxide-nushell-integration.nu" { } ''
    ${pkgs.zoxide}/bin/zoxide init nushell > "$out"
  '';

  intelliShellIntegration = pkgs.runCommand "intelli-shell-nushell-integration.nu" { } ''
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_DATA_HOME="$TMPDIR/data"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
    ${pkgs.intelli-shell}/bin/intelli-shell init nushell > "$out"
  '';
in
{
  # Nushell
  environment = {
    shells = [ pkgs.nushell ];

    systemPackages = with pkgs; [
      nushell
    ];

    # variables.SHELL = "${pkgs.nushell}/bin/nu";
    variables.SHELL = "${pkgs.bash}/bin/bash";

    etc."nushell/plugins/skim".source = "${pkgs.nushellPlugins.skim}/bin/nu_plugin_skim";
    etc."nushell/scripts/ultimate_extractor.nu".source =
      "${pkgs.nu_scripts}/share/nu_scripts/modules/data_extraction/ultimate_extractor.nu";
    etc."nushell/scripts/completions.nu".source = nuCompletions;
    etc."nushell/scripts/fzf.nu".source = fzfIntegration;
    etc."nushell/scripts/zoxide.nu".source = zoxideIntegration;
    etc."nushell/scripts/intelli-shell.nu".source = intelliShellIntegration;
  };

  # Fish
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting
    '';
  };

  # Bash, start Nu
  programs.bash = {
    interactiveShellInit = ''
      if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
        source  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
      fi

      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "nu" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.nushell}/bin/nu $LOGIN_OPTION
      fi
    '';
  };
}

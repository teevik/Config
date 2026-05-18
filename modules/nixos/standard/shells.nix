{ pkgs, ... }:
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

{ pkgs, ... }: {
  # Nushell
  environment.shells = [ pkgs.nushell ];
  users.users.teevik.shell = pkgs.nushell;
  environment.systemPackages = with pkgs; [
    nushell
  ];

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

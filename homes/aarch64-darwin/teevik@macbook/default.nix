{ pkgs
, lib
, osConfig
, ...
}: {
  home.stateVersion = "23.11";

  teevik = {
    themes = {
      everforest.enable = true;
      catppuccin.enable = false;
    };

    suites = {
      standard.enable = true;
    };

    apps = {
      neofetch.neofetchImage = null;
      kitty.opacity = 0.6;
    };
  };

  programs.fish.loginShellInit =
    let
      # This naive quoting is good enough in this case. There shouldn't be any
      # double quotes in the input string, and it needs to be double quoted in case
      # it contains a space (which is unlikely!)
      dquote = str: "\"" + str + "\"";

      makeBinPathList = map (path: path + "/bin");
    in
    ''
      fish_add_path --move --prepend --path ${lib.concatMapStringsSep " " dquote (makeBinPathList osConfig.environment.profiles)}
      set fish_user_paths $fish_user_paths
    '';

  home.packages = with pkgs; [
    discord
  ];
}

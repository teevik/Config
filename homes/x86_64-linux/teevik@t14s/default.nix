{ pkgs, ... }: {
  home.stateVersion = "23.11";

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
      ctf.enable = true;
    };
  };

  home.packages = with pkgs; [
    jetbrains.clion
  ];
}

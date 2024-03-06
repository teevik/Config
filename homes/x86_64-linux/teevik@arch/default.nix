{ ... }: {
  home.stateVersion = "23.11";

  targets.genericLinux.enable = true;

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
      ctf.enable = true;
    };
  };
}

{ ... }: {
  home.stateVersion = "24.11";

  teevik = {
    suites = {
      standard.enable = true;
      linux.enable = true;
      ctf.enable = true;
    };

    services = {
      hypridle.enable = true;
    };
  };
}

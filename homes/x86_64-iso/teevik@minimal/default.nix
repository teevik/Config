{ ... }: {
  home.stateVersion = "23.11";

  teevik = {
    apps = {
      git.enable = true;
      comma.enable = true;
    };
  };
}

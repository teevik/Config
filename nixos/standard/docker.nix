{ ... }: {
  virtualisation.docker.enable = true;
  users.users.teevik.extraGroups = [ "docker" ];
}

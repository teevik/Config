{ pkgs, ... }:
let
  initialHashedPassword =
    "$6$X19Q8OhBkw8xUegs$prAFssd1NxBR1qrdMUhqZX4Xqy02bTeNfCZw24YCMClQhp8Pox65w6PF5w7hV2foKfGytsXTwCB5pQ7FLwF7o/";
in
{
  imports = [
    ./networking.nix
    ./ssh.nix
  ];

  config = {
    documentation.man.generateCaches = false;

    # Auto-login
    services.getty.autologinUser = "teevik";

    # Boot
    boot = {
      supportedFilesystems = [ "bcachefs" ];
      kernelPackages = pkgs.linuxPackages_latest;
    };

    # User
    users.users = {
      teevik = {
        isNormalUser = true;
        home = "/home/teevik";
        group = "users";

        extraGroups = [ "wheel" ];


        inherit initialHashedPassword;
      };

      root = { inherit initialHashedPassword; };
    };
  };
}

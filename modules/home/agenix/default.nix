{ inputs, pkgs, ... }:
{
  imports = [ inputs.agenix.homeManagerModules.default ];

  config = {
    home.packages = [
      inputs.agenix.packages.${pkgs.system}.default
    ];

    age = {
      identityPaths = [ "/home/teevik/.ssh/id_rsa" ];

      secrets.copilot.file = ./copilot.age;
    };
  };
}

{ inputs
, pkgs
, ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    # include NixOS-WSL modules
    #<nixos-wsl/modules>
  ];

  wsl.enable = true;
  wsl.defaultUser = "teevik";

  teevik.suites = {
    standard.enable = true;
  };

  system.stateVersion = "22.11";
}

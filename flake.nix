{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    disko.url = "https://flakehub.com/f/nix-community/disko/1.tar.gz";
    agenix.url = "https://flakehub.com/f/ryantm/agenix/0.15.tar.gz";
  };

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations =
      let
        lib = nixpkgs.lib;

        foldersIn = path:
          let
            everything = builtins.readDir path;
            directories =
              lib.filterAttrs (name: type: type == "directory") everything;
          in
          builtins.attrNames directories;

        archs = foldersIn ./systems;
        hostnamesByArch = lib.genAttrs archs (arch: foldersIn ./systems/${arch});

        systems = lib.flatten (lib.mapAttrsToList
          (arch: systems: map (hostname: { inherit arch hostname; }) systems)
          hostnamesByArch);

        configurationFor = { arch, hostname }: {
          ${hostname} = lib.nixosSystem {
            system = arch;
            modules = [
              ./systems/${arch}/${hostname}/configuration.nix
              { networking.hostName = hostname; }
            ];

            specialArgs = { inherit inputs self; };
          };

        };
      in
      lib.mergeAttrsList (map configurationFor systems);
  };
}

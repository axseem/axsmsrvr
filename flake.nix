{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-25.05";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations = {
      axsmsrvr = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";

        modules = [
          ./configuration.nix
          inputs.disko.nixosModules.disko
        ];
      };
    };
  };
}

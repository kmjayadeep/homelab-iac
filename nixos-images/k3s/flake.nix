{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }:
    {
      nixosConfigurations.titania-worker1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules/k3s.nix
          ./modules/user.nix
          ./hosts/titania-worker1.nix
        ];
      };

      nixosConfigurations.titania-worker2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules/k3s.nix
          ./modules/user.nix
          ./hosts/titania-worker2.nix
        ];
      };

    };
}



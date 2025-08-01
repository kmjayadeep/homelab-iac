{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }:
    {
      # Titania K3s master node
      nixosConfigurations.titania = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules/k3s-master.nix
          ./modules/user.nix
          ./hosts/titania.nix
        ];
      };

      # Titania K3s worker node 1
      nixosConfigurations.titania-worker1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules/k3s.nix
          ./modules/user.nix
          ./hosts/titania-worker1.nix
        ];
      };

      # Titania K3s worker node 2
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



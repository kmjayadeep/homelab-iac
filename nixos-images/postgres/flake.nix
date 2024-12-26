{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }:
    {
      nixosConfigurations.helios = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules/backup.nix
          ./modules/monitoring.nix
          ./modules/pgweb.nix
          ./modules/postgres.nix
          ./modules/user.nix
          ./hosts/helios.nix
        ];
      };

    };
}


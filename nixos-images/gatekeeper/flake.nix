{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }:
    {
      nixosConfigurations.gatekeeper = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules/user.nix
          ./modules/adguard.nix
          ./hosts/gatekeeper.nix
        ];
      };

    };
}

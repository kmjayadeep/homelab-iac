{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  valheim-server = {
    url = "github:aidalgol/valheim-server-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, ... }:
    {
      nixosConfigurations.coder = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules/user.nix
          ./modules/valheim-server.nix
          ./modules/secret-valheim.nix
          ./hosts/fireland.nix
        ];
      };

    };
}

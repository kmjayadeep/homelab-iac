{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.valheim-server = {
    url = "github:aidalgol/valheim-server-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, valheim-server, ... }:
    {
      nixosConfigurations.fireland = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          valheim-server.nixosModules.default
          ./configuration.nix
          ./modules/user.nix
          ./modules/valheim-server.nix
          ./modules/backup.nix
          ./modules/tailscale.nix
          ./hosts/fireland.nix
        ];
      };
      nixosConfigurations.odin = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          valheim-server.nixosModules.default
          ./configuration.nix
          ./modules/user.nix
          ./modules/valheim-server.nix
          ./modules/backup.nix
          ./modules/tailscale.nix
          ./hosts/odin.nix
        ];
      };
      nixosConfigurations.chillyfries = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          valheim-server.nixosModules.default
          ./configuration.nix
          ./modules/user.nix
          ./modules/valheim-server.nix
          ./modules/backup.nix
          ./modules/tailscale.nix
          ./hosts/chillyfries.nix
        ];
      };

    };
}

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
          ./modules/adguard.nix
          ./modules/cloudflare.nix
          ./modules/tailscale.nix
          ./modules/user.nix
          ./hosts/gatekeeper.nix
        ];
      };

    };
}
